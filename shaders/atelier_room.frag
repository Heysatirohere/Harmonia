// Cenografia das Salas Cromáticas (AGENTS.md, seção 4).
// Pinta a Sala A e a Sala B e dissolve entre elas por uMix, com textura
// procedural (drapeado, reboco de afresco ou trama de tapeçaria), grão e vinheta.
#version 460 core

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform vec4 uColorA;
uniform float uStyleA;   // 0 = drapeado (veludo/seda), 1 = reboco (afresco/ocre/verdete), 2 = tapeçaria
uniform float uSeedA;
uniform vec4 uColorB;
uniform float uStyleB;
uniform float uSeedB;
uniform float uMix;      // 0 = só Sala A, 1 = só Sala B
uniform float uDrift;    // deslocamento vertical da textura acompanhando o scroll (em alturas de tela)

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p *= 2.03;
    a *= 0.5;
  }
  return v;
}

// Intensidade de luz da textura (1.0 = cor base pura)
float roomLight(vec2 frag, vec2 uv, float style, float seed) {
  vec2 q = uv + seed;

  if (style < 0.5) {
    // Drapeado: dobras diagonais deformadas por ruído, cristas de luz estreitas como em veludo/seda
    float warp = fbm(q * 1.1);
    float fa = sin((q.x * 1.6 + q.y * 0.9 + warp * 1.8) * 7.0);
    float fb = sin((q.x * 0.7 - q.y * 1.4 + warp * 1.1) * 4.2);
    float f = 0.5 + 0.5 * (0.65 * fa + 0.35 * fb);
    // Pico em 1.35: acima disso o texto marfim perde contraste nas cristas (AGENTS.md seção 3)
    return 0.62 + 0.73 * pow(f, 3.0) - 0.25 * pow(1.0 - f, 2.0);
  }

  if (style < 1.5) {
    // Reboco de afresco: manchas de pigmento, pinceladas horizontais e craquelado fino em algumas regiões
    float mottle = fbm(q * vec2(2.2, 3.4));
    float brush = fbm(vec2(q.x * 9.0, q.y * 2.2) + mottle * 2.0);
    vec2 cq = q * 7.0 + vec2(fbm(q * 3.0), fbm(q * 3.0 + 5.2)) * 1.5;
    float crack = smoothstep(0.012, 0.0, abs(noise(cq) - 0.5))
        * smoothstep(0.35, 0.65, fbm(q * 2.0 + 9.0)) * 0.14;
    // Pico em ~1.14: as Salas de reboco são as mais claras
    return mix(0.82, 1.08, mottle) + (brush - 0.5) * 0.12 - crack;
  }

  // Tapeçaria: manchas quentes, fibras e trama miúda
  float m = fbm(q * 3.0);
  float fibre = fbm(vec2(q.x * 40.0, q.y * 6.0));
  float weave = sin(frag.x * 1.3) * sin(frag.y * 1.3) * 0.05;
  return mix(0.6, 1.9, m) + (fibre - 0.5) * 0.35 + weave;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize.y;
  uv.y += uDrift;

  vec3 roomA = uColorA.rgb * roomLight(frag, uv, uStyleA, uSeedA);
  vec3 roomB = uColorB.rgb * roomLight(frag, uv, uStyleB, uSeedB);
  vec3 col = mix(roomA, roomB, uMix);

  // Grão de película
  col += (hash(frag + uSeedA) - 0.5) * 0.035;

  // Vinheta: luz de palco no centro-superior, bordas escurecidas
  vec2 c = frag / uSize - vec2(0.5, 0.3);
  float vig = 1.0 - smoothstep(0.25, 1.05, length(c * vec2(1.0, 0.9)));
  col *= mix(0.68, 1.08, vig);

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
