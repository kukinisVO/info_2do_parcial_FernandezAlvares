# Segundo Parcial — Match-3 (Infografía, I/2026)

Ronaldo Erick Fernandez Benavides 77737 
Andrew F. Alvarez Jordan 77766

Se implemento todos los B y M

Notas:

En el topUI está el score, el contador de movimientos restantes, y el nivel.
En el bottomUI está la tarea actual del nivel

Se removió la segunda hbox ubicada dentro de la hbox en el nodo de top UI
Se añadió una text label dentro de la hbox restante al mismo nivel que las otras text labels 
puede probarse al realizarse un combo 
Se modificaron los atributos de level config tal y como lo mencionaba posible el script
Se añadió un botón para salir de la game scene por simplemente ser mejor UI.

Se hizo una escena para el game menu, donde se puede jugar (que retomará desde él ultimo nivel que estabas) o seleccionar un nivel de manera individual.
Para la pantalla de victoria/derrota se hizo una escena nueva la cual redirige al juego principal. 
Se añadio un nodo para controlar el audio del juego, el cual se maneja por autoload.
Para la revision de estado trancado se debe apretar T, que pondrá un tablero sin solucion, y luego (PARA PROBAR REBARAJEADO) R para activar la función que solo lo reordenaría si no hay solución. Esta función se llama cuando ocurre de manera natural tambien.

Se hizo los efectos de lineas de 4 y 5 en grid.gd, pero los efectos especiales son parte de pieces.gd, donde se decidió que
- row, elimina todas las piezas del mismo color en la misma linea
- column,  elimina todas las piezas del mismo color en la misma columna
- adjacent, elimina todas las piezas del mismo color en un radio
- rainbow,  elimina todas las piezas en un mismo radio
- glitches, extra, se menciona abajo
 
Extras:
Se añadió transiciones entre escenas, para realizar el cambio de escena y que visualmente se vea smooth. Como un autoload, se puede usar de manera flexible en todo escenario.
Se añadió una cámara 2D dentro de la escena principal para el efecto de sacudida
Se añadio la semilla diaria
Se añadio un shader (https://godotshaders.com/shader/test-crt-vcr/) al juego
Se añadio una pieza personalizada "glitcheada", que quita 1 al contador de movimientos cuando hace match, tiene shader único como también sonido único. El shader igual lo obtuve de internet (https://godotshaders.com/shader/weird-glitch-shader/)
Se hizo un menu de selección de niveles, que bloquea todos los niveles que no se han jugado o te faltan finalizar. Se adapta a los archivos de nivel disponible y tiene tantos iconos para cada nivel, como hay para cada pieza individual.


## Entrega

1. Haz un **fork** (o copia a un repo propio) de este proyecto base.
2. Trabaja con **commits frecuentes y descriptivos**: el historial se revisa.
3. En **tu** README, escribe cómo correr el juego, qué mecánicas implementaste y los
   recursos externos que consultaste (con enlaces).
4. Entrega la **URL de tu repositorio** por Moodle antes de la fecha límite.

No subas la carpeta `.godot/` (ya está en `.gitignore`).
