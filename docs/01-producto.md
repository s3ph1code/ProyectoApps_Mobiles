# 01 · Producto

## Qué es

Doulapp es una aplicación móvil de acompañamiento durante el embarazo y, sobre todo, el **posparto temprano**.

Su enfoque no es el bebé. La app acompaña a la persona que cuida: la ayuda a encontrar pequeños espacios para sí misma, a entender cómo se siente y a apoyarse en una comunidad de madres.

**Concepto central:** «Tu bienestar también importa.»
**Subtítulo:** «Acompañamiento posparto, sin prejuicios.»

## A quién va dirigida

La usuaria de referencia es una madre en posparto temprano que:

- Duerme poco y usa el móvil **con una sola mano**, mientras amamanta o arrulla.
- Carga con agotamiento físico y mental, culpa, aislamiento y fatiga de decisión.
- Siente que perdió su identidad y quiere recuperar pequeños espacios propios.
- Es desconfiada: la han decepcionado, y le cuesta creer que quien ofrece ayuda vaya a cumplir.
- Es introvertida desde que nació su bebé, y le cuesta relacionarse.

No se diseña para una sola persona: ella representa necesidades que existen en muchas otras.

## Qué debe transmitir

Calma · Privacidad · Acompañamiento · Confianza · Autonomía · Cuidado · Cercanía · Cero juicios

## Qué NO debe parecer

- Una aplicación médica u hospitalaria
- Una aplicación infantil
- Una aplicación de productividad
- Una app de maternidad excesivamente rosa
- Una red social al uso

## Principios de interacción

Estos principios son requisitos, no preferencias estéticas:

**Una sola mano.** Las acciones principales viven en el tercio inferior de la pantalla.

**Objetivos táctiles grandes.** Botón primario de 56 px de alto. Filas y tarjetas de 56 px o más. Nunca menos de 44 px.

**Poco texto por pantalla.** Un titular, una frase de apoyo y una decisión. Nunca dos preguntas compitiendo.

**Máximo cuatro opciones por pregunta**, y siempre con un valor por defecto razonable, para reducir la fatiga de decisión.

**Lenguaje sin culpa.** Nada de metas, rachas ni evaluación del desempeño. Se acompaña, no se mide.

**Evitar formularios largos.** Máximo cuatro campos por pantalla.

## Identidad visual

Paleta (usar como tokens en el tema de Flutter, ver `docs/04-arquitectura-flutter.md`):

| Rol | Hex |
|---|---|
| Primario — verde salvia | `#588157` |
| Primario claro | `#A3B18A` |
| Verde oscuro / énfasis | `#395A3F` |
| Fondo principal — crema | `#F7F5EF` |
| Fondo secundario — beige | `#EDE8DE` |
| Superficies | `#FFFFFF` |
| Texto principal | `#26382D` |
| Texto secundario | `#68736C` |
| Éxito (solo estado) | `#6F9B72` |
| Advertencia (solo estado) | `#D8B36A` |
| Error / riesgo (solo estado) | `#B85C5C` |

Restricciones de color: **sin rosa como color dominante, sin colores saturados, sin degradados fuertes.** Los colores de estado se usan solo como estado, nunca como decoración.

**Tipografía:** Fraunces (SemiBold) para titulares, Inter para interfaz y cuerpo.

**Estilo:** premium wellness + editorial minimalista + mobile-first. Esquinas suavemente redondeadas, mucho espacio en blanco, sombras muy sutiles, iconografía de línea, ilustraciones orgánicas.

**Pantalla de referencia:** 390 × 844 px (iPhone 14 / 15).
