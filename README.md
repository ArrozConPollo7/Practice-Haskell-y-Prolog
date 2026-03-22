# Sistema de Registro Universitario — Haskell

> **Práctica I · Versión A** — Asignatura ST0244 Lenguajes de Programación · Universidad EAFIT

---

## Descripción

Sistema funcional para gestionar el **ingreso y salida de estudiantes del campus universitario**, desarrollado íntegramente en el paradigma funcional con Haskell.

---

## Especificaciones

| Campo | Detalle |
|---|---|
| **Materia** | ST0244 — Lenguajes de Programación |
| **Docente** | Alexander Narváez Berrío |
| **Valor** | 15% de la nota final |
| **Paradigma** | Funcional |

---

## Funcionalidades

| # | Función | Descripción |
|---|---|---|
| 1 | **Check In** | Registro de entrada del estudiante solicitando su ID y almacenando la hora de ingreso |
| 2 | **Search by ID** | Búsqueda de estudiantes que se encuentran actualmente dentro de la universidad |
| 3 | **Time Calculation** | Cálculo automático de la estancia en formato legible (horas y minutos) |
| 4 | **Students List** | Carga de registros desde `University.txt` y visualización en terminal |
| 5 | **Check Out** | Registro de salida y actualización de la persistencia de datos |

---

## Análisis Técnico

### 1. Modelo de Datos e Inmutabilidad

En Haskell **no se modifican variables**. Se utiliza una estructura `Estudiante` definida con `data`. Para "actualizar" un registro (como en el Check Out), el programa usa `map` para recorrer la lista actual y generar una **nueva lista** con el dato cambiado, preservando la integridad de los datos originales.

### 2. Gestión de Tiempo

Se implementó la **Opción 3** de la guía: el tiempo se almacena como un entero que representa los minutos transcurridos desde las `00:00`.

```
08:30 AM  →  510 minutos
```

Esto permite calcular la permanencia mediante una resta simple:

```
Permanencia = TiempoSalida - TiempoEntrada
```

### 3. Persistencia y Lazy Evaluation

El programa lee y escribe en `University.txt`. Debido a que Haskell es un lenguaje de **evaluación perezosa (Lazy)**, el código fuerza la lectura completa del archivo antes de permitir una nueva escritura, evitando conflictos de acceso durante la ejecución.

### 4. Recursividad en el Menú

A falta de ciclos imperativos (`while`), el menú principal es una **función recursiva**. Al finalizar cada operación, la función se llama a sí misma para mantener el programa en ejecución hasta que el usuario decida salir.

---

## Instrucciones de Ejecución

### Requisitos

- [GHC — Glasgow Haskell Compiler](https://www.haskell.org/ghc/)

### Pasos

1. Coloque `Main.hs` y `University.txt` en la misma carpeta.
2. Abra una terminal en esa carpeta y ejecute:

```bash
runhaskell Main.hs
```

---

## Formato de Almacenamiento

Los datos se persisten en `University.txt` como lista de estructuras nativas de Haskell:

```haskell
Estudiante {idEst = "123", entrada = 480, salida = -1}
```

> **Nota:** Un valor de `-1` en el campo `salida` indica que el estudiante aún permanece dentro de la universidad.

---
