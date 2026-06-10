# Proyecto Corto III: Diseño Digital Sincrónico en HDL (No se si hay que cambiar el titulo) 

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

https://github.com/Bran245/Proyecto-3-Dise-o-L-gico/blob/dc16a19ec5eb1eee7d3ceb61d16613404f0bdf40/SISTEMA%20DE%20BLOQUES.jpeg
### 2.1 Diagrama de bloques de subsistema de división
Poner foto

### 2.2 Diagrama de bloques de subsistema de lectura 

### 2.3 Diagrama de bloques de subsistemade display 

## 3 Diagramas de las FSM 

### 3.1 FSM de división 

### 3.2 FSM de lectura 
