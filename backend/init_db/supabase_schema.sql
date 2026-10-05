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
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    looks_generated_today INTEGER NOT NULL DEFAULT 0,
    looks_counter_date DATE,
    looks_signatures_today JSONB NOT NULL DEFAULT '[]'::jsonb,
    items_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2.1 Cota diária que vira o dia (RN02) e visibilidade de perfil (RN05) em bancos criados antes dessas colunas
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS looks_counter_date DATE;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS looks_signatures_today JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT TRUE;
-- Nome exibido no feed (RF14), espelhado pela API a partir do user_metadata.full_name
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS display_name VARCHAR(100);

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

-- 4.1 Feedback de recomendações (RF13): aprovações e descartes de looks sugeridos
CREATE TABLE IF NOT EXISTS public.look_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    item_ids JSONB NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('APPROVED', 'DISCARDED')),
    occasion VARCHAR(50) NOT NULL,
    ihe_percentage DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_look_feedback_user_id ON public.look_feedback(user_id);

-- 4.1 Feed comunitário (RF14, RF15, RN05)
-- Posts só aparecem para outros se o post e o perfil do autor forem públicos; a regra
-- fica na API, que é o único caminho de leitura do feed.
CREATE TABLE IF NOT EXISTS public.community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    caption TEXT NOT NULL,
    occasion VARCHAR(50) NOT NULL,
    style_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    item_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    ihe_percentage DOUBLE PRECISION,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_community_posts_user_id ON public.community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_created_at ON public.community_posts(created_at DESC);

CREATE TABLE IF NOT EXISTS public.post_reactions (
    post_id UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    PRIMARY KEY (post_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_post_reactions_user_id ON public.post_reactions(user_id);

CREATE TABLE IF NOT EXISTS public.saved_posts (
    post_id UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    PRIMARY KEY (post_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_saved_posts_user_id ON public.saved_posts(user_id);

-- 5. Row Level Security (RLS) para Blindagem Multi-Tenant no Supabase
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clothing_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.look_feedback ENABLE ROW LEVEL SECURITY;
-- Feed: o app não lê essas tabelas direto; cada um só enxerga as próprias linhas por fora da API
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;

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

DROP POLICY IF EXISTS "Usuários gerenciam apenas o próprio feedback de looks" ON public.look_feedback;
CREATE POLICY "Usuários gerenciam apenas o próprio feedback de looks"
ON public.look_feedback
FOR ALL
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários gerenciam apenas os próprios posts" ON public.community_posts;
CREATE POLICY "Usuários gerenciam apenas os próprios posts"
ON public.community_posts
FOR ALL
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários gerenciam apenas as próprias curtidas" ON public.post_reactions;
CREATE POLICY "Usuários gerenciam apenas as próprias curtidas"
ON public.post_reactions
FOR ALL
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários gerenciam apenas os próprios salvos" ON public.saved_posts;
CREATE POLICY "Usuários gerenciam apenas os próprios salvos"
ON public.saved_posts
FOR ALL
USING (auth.uid() = user_id);

-- 6. Configuração do Bucket do Supabase Storage para Peças com Canal Alfa
INSERT INTO storage.buckets (id, name, public)
VALUES ('wardrobe-items', 'wardrobe-items', true)
ON CONFLICT (id) DO NOTHING;

-- Política de Storage: Leitura pública ou autenticada, upload autenticado
DROP POLICY IF EXISTS "Upload autenticado de fotos de roupas" ON storage.objects;
-- Cada usuário só envia fotos para a própria pasta (<user_id>/...), o que permite
-- apagar tudo dele na exclusão da conta (RN04)
CREATE POLICY "Upload autenticado de fotos de roupas"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'wardrobe-items' AND (storage.foldername(name))[1] = auth.uid()::text);

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

-- 8. Direito ao Esquecimento (RN04)
-- A exclusão da conta é feita pela API (DELETE /api/v1/users/me) com a service role key:
-- apaga as fotos do Storage, os registros e o login. A antiga RPC apagava só o banco
-- e deixava as fotos no bucket, por isso foi removida.
DROP FUNCTION IF EXISTS public.delete_own_account();
