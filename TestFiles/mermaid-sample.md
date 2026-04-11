---
title: Mermaid Sample
status: test
---

# Mermaid rendering smoke test

Three diagrams, one deliberately broken.

## Flowchart

```mermaid
graph TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Celebrate]
    B -->|No| D[Debug]
    D --> A
```

## Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant QL as Quick Look
    participant E as Extension
    U->>QL: Press spacebar
    QL->>E: preparePreview
    E-->>QL: HTML + SVG
    QL-->>U: Rendered diagram
```

## Broken (should show an error, not crash the preview)

```mermaid
this is not valid mermaid syntax at all
    --> nope
```

Regular prose after the diagrams should still render fine.
