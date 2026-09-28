-- ==============================================================================
-- HarmonIA — Script de Migração e Configuração para o Supabase (PostgreSQL 16)
-- Conforme Regras de Negócio Multi-Tenant (RN01) e Extensão pgvector (512d)
-- ==============================================================================

-- 1. Habilitar a extensão pgvector para cálculo de similaridade de cosseno
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Tabela de Usuários (Sincronizável com auth.users do Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    body_shape VARCHAR(50),
    seasonal_palette VARCHAR(50),
    style_vector vector(512),
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    looks_generated_today INTEGER NOT NULL DEFAULT 0,
    items_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. Tabela de Peças do Acervo Virtual
CREATE TABLE IF NOT EXISTS public.clothing_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(100),
    image_url VARCHAR(500) NOT NULL,
    dominant_l DOUBLE PRECISION NOT NULL,
    dominant_a DOUBLE PRECISION NOT NULL,
    dominant_b DOUBLE PRECISION NOT NULL,
    formality_score DOUBLE PRECISION NOT NULL,
    cut_type VARCHAR(100),
    style_embedding vector(512),
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. Índices para Otimização de Consultas e Multi-Tenant (RN01)
CREATE INDEX IF NOT EXISTS idx_clothing_items_user_id ON public.clothing_items(user_id);
CREATE INDEX IF NOT EXISTS idx_clothing_items_category ON public.clothing_items(category);

-- Índice HNSW vetorial para busca ultrarrápida por similaridade de cosseno
CREATE INDEX IF NOT EXISTS idx_clothing_items_style_embedding 
ON public.clothing_items 
USING hnsw (style_embedding vector_cosine_ops);

-- 5. Row Level Security (RLS) para Blindagem Multi-Tenant no Supabase
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clothing_items ENABLE ROW LEVEL SECURITY;

-- Política de RLS: O usuário só acessa seus próprios dados
DROP POLICY IF EXISTS "Usuários podem gerenciar suas próprias contas" ON public.users;
CREATE POLICY "Usuários podem gerenciar suas próprias contas"
ON public.users
FOR ALL
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Usuários podem gerenciar apenas suas próprias roupas" ON public.clothing_items;
CREATE POLICY "Usuários podem gerenciar apenas suas próprias roupas"
ON public.clothing_items
FOR ALL
USING (auth.uid() = user_id);

-- 6. Configuração do Bucket do Supabase Storage para Peças com Canal Alfa
INSERT INTO storage.buckets (id, name, public)
VALUES ('wardrobe-items', 'wardrobe-items', true)
ON CONFLICT (id) DO NOTHING;

-- Política de Storage: Leitura pública ou autenticada, upload autenticado
DROP POLICY IF EXISTS "Upload autenticado de fotos de roupas" ON storage.objects;
CREATE POLICY "Upload autenticado de fotos de roupas"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'wardrobe-items');

DROP POLICY IF EXISTS "Visualização pública de roupas recortadas" ON storage.objects;
CREATE POLICY "Visualização pública de roupas recortadas"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'wardrobe-items');

-- 7. Sincronização Supabase Auth -> public.users (RF01)
-- A senha é gerenciada exclusivamente pelo Supabase Auth; hashed_password
-- recebe um marcador para respeitar a restrição NOT NULL do modelo legado.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.users (id, email, hashed_password)
    VALUES (NEW.id, NEW.email, 'managed_by_supabase_auth')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- Mantém o e-mail espelhado após confirmação de troca (RF18)
CREATE OR REPLACE FUNCTION public.handle_auth_user_email_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    UPDATE public.users SET email = NEW.email WHERE id = NEW.id;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_email_changed ON auth.users;
CREATE TRIGGER on_auth_user_email_changed
AFTER UPDATE OF email ON auth.users
FOR EACH ROW
WHEN (OLD.email IS DISTINCT FROM NEW.email)
EXECUTE FUNCTION public.handle_auth_user_email_change();

-- 8. Direito ao Esquecimento (RN04): exclusão definitiva pelo próprio usuário
-- Remove auth.users; public.users e clothing_items caem em cascata.
-- Obs.: arquivos do Storage precisam ser removidos pela Storage API
-- (o Supabase bloqueia DELETE direto em storage.objects).
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    uid UUID := auth.uid();
BEGIN
    IF uid IS NULL THEN
        RAISE EXCEPTION 'Sessão não autenticada' USING ERRCODE = '42501';
    END IF;

    DELETE FROM public.users WHERE id = uid;
    DELETE FROM auth.users WHERE id = uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
