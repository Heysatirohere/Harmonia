"""
Gera app/vision/garment_labels.npz: os vetores de texto do CLIP para os rótulos de
categoria e estampa de app/vision/garment_attributes.py (RF05).

Roda só no desenvolvimento, quando um rótulo muda; a API usa o arquivo gerado e nunca
baixa o modelo de texto. Usa a MESMA revisão do CLIP do vetor de estilo (config.py), para
que imagem e texto caiam no mesmo espaço.

    pip install tokenizers   # só para este script, fora do requirements.txt
    python -m scripts.build_garment_labels
"""

import os
import sys

import httpx
import numpy as np

from app.vision.garment_attributes import GARMENT_LABELS, LABELS_PATH, PATTERN_LABELS, all_prompts

REVISION = "d15189d7028b43f1d3e65039190477f6af591c2a"
BASE = f"https://huggingface.co/Xenova/clip-vit-base-patch32/resolve/{REVISION}"
FILES = {"text_model.onnx": f"{BASE}/onnx/text_model.onnx", "tokenizer.json": f"{BASE}/tokenizer.json"}
CACHE = os.path.expanduser("~/.cache/harmonia/clip-text")


def _fetch(name: str, url: str) -> str:
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        os.makedirs(CACHE, exist_ok=True)
        print(f"Baixando {name}…")
        with httpx.stream("GET", url, follow_redirects=True, timeout=300.0) as response:
            response.raise_for_status()
            with open(f"{path}.part", "wb") as out:
                for chunk in response.iter_bytes(1 << 20):
                    out.write(chunk)
        os.replace(f"{path}.part", path)
    return path


def main() -> int:
    from tokenizers import Tokenizer
    import onnxruntime as ort

    tokenizer = Tokenizer.from_file(_fetch("tokenizer.json", FILES["tokenizer.json"]))
    session = ort.InferenceSession(_fetch("text_model.onnx", FILES["text_model.onnx"]), providers=["CPUExecutionProvider"])
    inputs = {i.name for i in session.get_inputs()}

    def embed(text: str) -> np.ndarray:
        # Uma frase por vez, sem preenchimento: o CLIP lê o token de fim da própria frase
        ids = np.array([tokenizer.encode(text).ids], dtype=np.int64)
        feed = {"input_ids": ids}
        if "attention_mask" in inputs:
            feed["attention_mask"] = np.ones_like(ids)
        vector = session.run(["text_embeds"], feed)[0][0]
        return vector / np.linalg.norm(vector)

    def label_vector(prompts):
        mean = np.mean([embed(p) for p in prompts], axis=0)
        return (mean / np.linalg.norm(mean)).astype(np.float32)

    garment_prompts, pattern_prompts = all_prompts()
    np.savez_compressed(
        LABELS_PATH,
        garment_keys=np.array([g.key for g in GARMENT_LABELS]),
        garment_vectors=np.stack([label_vector(p) for p in garment_prompts]),
        pattern_keys=np.array([p.key for p in PATTERN_LABELS]),
        pattern_vectors=np.stack([label_vector(p) for p in pattern_prompts]),
        revision=np.array(REVISION),
    )
    print(f"{len(GARMENT_LABELS)} peças e {len(PATTERN_LABELS)} estampas gravadas em {LABELS_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
