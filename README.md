# Proyecto Corto III: División de enteros

**EL-3307 Diseño Lógico — I Semestre 2026**  
**Escuela de Ingeniería Electrónica, TEC**

---


## 1.Descripción General del Sistema 
En el presente proyecto, se busca implementar un divisor de división entera sin signo sobre una FPGA, operando solo con un reloj de 27 MHz. Este sistema va a recibir dos números decimales ingresado por medio de un teclado hexadecimal, donde posterior a esto, calculara el cociente y residuo, para mostrar el resultado en un display de 7 de segmentos. 
El sistema de divide en cuatro subsistemas conectados en cadena, donde la comunicación entre estos, será por medio de un protocolo de banderas. El subsistema de lectura indica al de división cuando los operandos son válidos, y el división al del display cuando el resultado sea estable. Todos los subsistemas actúan de manera sincrónica con el mismo reloj. El flujo completo se ve como: 

### 1.1 Subsistema de lectura 
Tiene como función capturar dos números decimales desde el teclado, y entregarlos en forma decimal al subsistema de división.
A nivel interno, opera en 4 etapas:
- Sincronizados de dos flip-flops que lleva las señales físicas del teclado al reloj interno 
- Un módulo debounce que filtra los rebotes mecánicas, esperando un tiempo de 20ms de estabilidad en la señal antes de aceptarla 
- El escáner de teclado activa las columnas del teclado en rotación aproximadamente a 1 kHz, y lee las filas para identificar que tecla se esta presionando
- Una etapa FSM de control, que recibe los pulsos y la guía la captura secuencial, primero acumulando los dígitos del dividendo A (máximo 63 o 127 según la versión) espera la tecla “#” como confirmación y luego captura el divisor B (máximo 15 o 127). Y al recibir la segunda confirmación, activa data_valid. La tecla “*” funcionara como borrado, reiniciando la captura desde el inicio.

### 1.2 Subsistema de Cálculo de división entera 
Su función es calcular el cociente Q y el residuo R de la división entera A ÷ B, implementando el algoritmo iterativo descrito el enunciado del proyecto. 
El algoritmo opera desplazando bit a bit el dividendo A hacia un registro de residuo parcial R, restando el divisor B en cada paso, y decidiendo si el bit correspondiente del cociente Q es 1 o 0 según el signo del resultado. Este proceso se repite N veces, donde N es el ancho en bits del dividendo.
La arquitectura sigue el esquema clásico de datapath más unidad de control. El datapath contiene los registros de A, B, Q y R, un restador con bit de signo, un multiplexor que selecciona entre el residuo nuevo o el anterior, y un contador de iteraciones. La unidad de control es una FSM de cuatro estados: IDLE espera la señal data_valid; LOAD carga A y B en los registros del datapath durante un ciclo; ITERATE activa el datapath ciclo a ciclo hasta completar N iteraciones; DONE mantiene Q y R estables y activa la señal done hacia el subsistema de display.
Adicionalmente se implementó una versión con pipeline, donde cada iteración del algoritmo corresponde a una etapa registrada independiente. Esto corta el camino crítico combinacional y permite operar a la frecuencia objetivo de 27 MHz, a cambio de una latencia fija de N ciclos de reloj.

### 1.3 Subsistema de conversión binario a BCD
Su función es convertir los resultados binarios Q y R a dígitos decimales en formato BCD, necesarios para el display.
Se implementa el algoritmo double-dabble (también conocido como shift-and-add-3) de forma combinacional y sin registros internos. El proceso desplaza el número binario bit a bit hacia un registro BCD; antes de cada desplazamiento, cualquier dígito BCD que sea mayor o igual a 5 recibe una corrección sumándole 3, lo que garantiza que el resultado final sea BCD válido. El módulo es completamente parametrizable: con INPUT_WIDTH=6 y BCD_DIGITS=2 cubre el rango base (0–63), y con INPUT_WIDTH=7 y BCD_DIGITS=3 cubre el rango extendido (0–127). Se instancia de forma independiente para el cociente y para el residuo

### 1.4 Subsistema de despliegue en display en 7 segmentos 
Su función es mostrar en los displays físicos el cociente o el residuo de la división, según seleccione el usuario.
Internamente, un controlador recibe los dígitos BCD del cociente y del residuo, y según el estado de una señal de selección (toggle activado por un botón dedicado) elige cuál de los dos resultados enviar al multiplexor de display. El multiplexor activa los displays de forma rotativa a aproximadamente 1 kHz por dígito, frecuencia suficiente para eliminar el parpadeo visible. En cada turno, el dígito BCD activo pasa por un decodificador que genera las 7 señales de segmento en lógica activo-bajo. El botón de selección pasa por el mismo proceso de sincronización y debounce que el teclado, garantizando que no genere transiciones espurias.

## 2 Diagrama de bloques de los subsistemas 
![Diagrama 1](https://github.com/Bran245/Proyecto-3-Dise-o-L-gico/blob/dc16a19ec5eb1eee7d3ceb61d16613404f0bdf40/SISTEMA%20DE%20BLOQUES.jpeg)


### 2.1 Diagrama de bloques de subsistema de división
![Division](https://github.com/Bran245/Proyecto-3-Dise-o-L-gico/blob/d678c44a781851f90d964f537b757af369ff9a84/SUBSISTEMA%20DE%20DIVISION.jpeg)

### 2.2 Diagrama de bloques de subsistema de lectura 
![Lectura](https://github.com/Bran245/Proyecto-3-Dise-o-L-gico/blob/5a03f0a52945ce3f36ad79c58fb5cd426defacd9/subsistema%20de%20lecura.jpeg)
### 2.3 Diagrama de bloques de subsistemade display 
![Display](https://github.com/Bran245/Proyecto-3-Dise-o-L-gico/blob/55dd8076a3f82dac0ca4be6cb5228f83864d53ed/Subsistema%20Display.jpeg)
## 3 Diagramas de las FSM 

### 3.1 FSM de división 
![Division](https://github.com/Bran245/Proyecto-3-Dise-o-L-gico/blob/fe98cec8d6d57a42e2ec9f989af0ea48f7ebefec/FSM%20DE%20DIVISION.jpeg)
### 3.2 FSM de lectura 
![FSM Lectura](https://github.com/Bran245/Proyecto-3-Dise-o-L-gico/blob/f9353112d4b6452476164b13a19cb9ff69fbf37e/FSM%20Lectura.jpeg)
## 4. Simulación funcional del sistema completo

La simulación funcional del módulo `div_pipeline` se realizó en EDA Playground utilizando Icarus Verilog 12.0 con SystemVerilog. El testbench aplica 13 casos de prueba que cubren tanto los requisitos base (dividendo hasta 63, divisor hasta 15) como los del puntaje extra (dividendo hasta 127, divisor hasta 31).
El protocolo de simulación por cada caso es el siguiente:
1. En un flanco negativo de reloj se presentan `A`, `B` y `valid=1`.
2. En el siguiente flanco negativo se baja `valid=0`.
3. Se espera exactamente 7 ciclos de reloj (latencia fija del pipeline con `A_BITS=7`).
4. Se verifican `Q` y `R` contra los valores esperados.
Los resultados obtenidos se muestran en la siguiente imagen, en la cual, se evidencia como el sistema es capaz de realizar la división solicitada en su estado base, asi como la de los punto extra:

![Test](https://github.com/Bran245/Proyecto-3-Dise-o-L-gico/blob/4be0083887694ac75d99fd146e8b16b35689cde5/test.jpeg)

El flujo de datos completo en hardware sigue la siguiente secuencia:

1. El usuario ingresa el dividendo A dígito por dígito mediante el teclado 4×4 y confirma con `#`.
2. El usuario ingresa el divisor B y confirma con `#`.
3. El módulo `top` activa `valid=1` por un ciclo, enviando A y B al `div_pipeline`.
4. Tras 7 ciclos de reloj el pipeline produce `done=1`, `Q` y `R` estables.
5. El módulo `top` captura Q y R en registros de salida.
6. El módulo `binary_to_bcd` convierte Q y R a BCD.
7. El `display_7seg` muestra el cociente por defecto; presionando `#` alterna al residuo.

---

## 5. Análisis de consumo de recursos y potencia

> **Nota:** Los siguientes valores deben completarse con los reportes generados por la herramienta de síntesis para la TangNano 9k.

| Recurso | Utilizado | Disponible | Porcentaje |
|---------|-----------|------------|------------|
| LUTs | — | 8640 | — |
| Flip-Flops | — | 6480 | — |
| Bloques de RAM | — | 26 | — |
| DSPs | — | 20 | — |

**Consumo de potencia estimado:**

| Dominio | Potencia (mW) |
|---------|---------------|
| Lógica combinacional | — |
| Registros (pipeline) | — |
| I/O | — |
| **Total** | — |

Se espera un consumo moderado dado que el diseño es completamente síncrono con un único dominio de reloj de 27 MHz, sin bloques de memoria ni DSPs dedicados. El pipeline de `A_BITS=7` etapas introduce registros adicionales para propagar B, A, Q parcial y valid a través de cada etapa, lo que incrementa el uso de flip-flops respecto a una implementación combinacional pura.

---

## 6. Velocidad máxima de reloj

El diseño fue desarrollado para operar a la frecuencia de referencia de la TangNano 9k de **27 MHz**, sobre el dispositivo **GW1NR-9C (QFN88P, C6/I5)**. La ruta crítica del sistema se encuentra dentro de cada fila del divisor (`div_row`), específicamente en la cadena de acarreo de las `B_BITS+1` celdas `div_cell`.

Con `B_BITS=5` se tienen 6 celdas en serie por fila, cada una compuesta por un sumador de 1 bit. Al introducir el pipeline entre filas se corta la propagación de acarreo entre filas, reduciendo la ruta crítica a una sola fila en lugar de las `A_BITS=7` filas completas.

Durante la síntesis se detectó inicialmente un fallo de timing en `display_7seg` (26.21 MHz antes del fix), causado por la ruta combinacional larga desde `binary_to_bcd` → lógica de blanking → selección de segmentos. Se resolvió registrando las entradas `dig3..dig0` y `enable` al inicio del módulo, cortando esa ruta en dos ciclos separados.

Los resultados del análisis de timing post Place & Route (PnR) con la herramienta Gowin son:

| Métrica | Valor |
|---------|-------|
| Dispositivo | GW1NR-9C (QFN88P, C6/I5) |
| Frecuencia objetivo | 27.00 MHz |
| Período objetivo | 37.04 ns |
| Frecuencia máxima post-placement | 40.73 MHz (PASS) |
| Frecuencia máxima post-routing | 48.46 MHz (PASS) |
| Ruta crítica post-placement (lógica) | 10.8 ns |
| Ruta crítica post-placement (routing) | 9.8 ns |
| Ruta crítica post-routing (lógica) | 9.8 ns |
| Ruta crítica post-routing (routing) | 9.1 ns |
| Slack (todos los endpoints) | Positivo |
| Restricciones de timing | Todas PASS |

El diseño supera el objetivo de 27 MHz con un margen considerable — **48.46 MHz post-routing**, lo que representa un margen del 79% sobre la frecuencia requerida. Todos los histogramas de slack reportados fueron positivos, confirmando que no existe ninguna violación de timing en el diseño final.

El tiempo total de Place & Route fue aproximadamente 30.16 segundos (HeAP + SA + Router1).

---

## 7. Problemas encontrados y soluciones aplicadas

## 7. Problemas encontrados y soluciones aplicadas

Durante el desarrollo del proyecto se identificaron y resolvieron los siguientes problemas:

**Problema 1 — Conversor BCD incorrecto**

El conversor binario a BCD original producía resultados incorrectos en la representación decimal. El problema radicaba en que no separaba correctamente las centenas, decenas y unidades del valor binario de entrada. Se sustituyó por una implementación del algoritmo double-dabble que opera correctamente sobre los tres dígitos decimales, garantizando una conversión precisa para todos los valores del rango soportado.

**Problema 2 — Condición de carrera en la FSM de control**

Se presentaba una situación en la que la lógica combinacional de la FSM terminaba de evaluar su estado actual mientras la siguiente etapa del datapath ya estaba solicitando datos, generando un conflicto entre ambas. Esto provocaba que operaciones como la división no se ejecutaran correctamente. La solución fue introducir una bandera de control (`valid/calcular`) que sincroniza el momento exacto en que los operandos son válidos y la división debe iniciarse, eliminando la ambigüedad entre el fin de la evaluación combinacional y el inicio del cálculo.

**Problema 3 — Ausencia de transistores BJT en el manejo del display**

Inicialmente los segmentos del display de 7 segmentos se conectaron directamente desde los pines de la FPGA, lo cual no es adecuado por las limitaciones de corriente de los pines. Se implementaron transistores BJT como etapa de potencia entre la FPGA y el display, tal como lo especifica el enunciado del proyecto, permitiendo el manejo correcto de la corriente necesaria para cada segmento.

**Problema 4 — Visualización incorrecta del dígito 3 en la entrada de B (no resuelto)**

Al ingresar el dígito `3` como parte del divisor B, el display lo muestra visualmente como `67`. Este es un problema exclusivo de la representación en el display — el valor que efectivamente llega al divisor es el correcto (`3`), por lo que los cálculos no se ven afectados.





