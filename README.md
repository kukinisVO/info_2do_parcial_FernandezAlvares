# Segundo Parcial — Match-3 (Infografía, I/2026)

Ronaldo Erick Fernandez Benavides 77737 
Andrew F. Alvarez Jordan 77766

Notas:

Se implemento todos los B y M
Se removió la segunda hbox ubicada dentro de la hbox en el nodo de top UI
Se añadió una text label dentro de la hbox restante al mismo nivel que las otras text labels 
puede probarse al realizarse un combo 
Se modificaron los atributos de level config tal y como lo mencionaba posible el script

Para la pantalla de victoria se hizo una escena nueva la cual redirige al juego principal. Se muestran las pantallas de victoria y derrota 
Se añadio un nodo para controlar el audio del juego
Para la revision de estado trancado se debe apretar T, que pondrá un tablero sin solucion, y luego R para activar la función que solo lo reordenaría si no hay solución. Esta función se llama cuando ocurre de manera natural tambien.
Se hizo los efectos de lineas de 4 y 5 en grid.gd, pero los efectos especiales son parte de pieces.gd, donde se decidió que
- row, elimina todas las piezas del mismo color en la misma linea
- column,  elimina todas las piezas del mismo color en la misma columna
- adjacent, elimina todas las piezas del mismo color en un radio
- rainbow,  elimina todas las piezas en un mismo radio

Extras:
Se añadió una cámara 2D dentro de la escena principal para el efecto de sacudida
Se añadio la semilla diaria
Se añadio un shader (https://godotshaders.com/shader/test-crt-vcr/) al juego


## Entrega

1. Haz un **fork** (o copia a un repo propio) de este proyecto base.
2. Trabaja con **commits frecuentes y descriptivos**: el historial se revisa.
3. En **tu** README, escribe cómo correr el juego, qué mecánicas implementaste y los
   recursos externos que consultaste (con enlaces).
4. Entrega la **URL de tu repositorio** por Moodle antes de la fecha límite.

No subas la carpeta `.godot/` (ya está en `.gitignore`).
