:- dynamic estudiante/3. % id, entrada, salida (0 si no ha salido)

% --- Cargar desde archivo ---
cargar_datos :-
    retractall(estudiante(_, _, _)),
    exists_file('University.txt'),
    setup_call_cleanup(
        open('University.txt', read, Flujo),
        leer_lineas(Flujo),
        close(Flujo)
    ),
    writeln('Datos cargados exitosamente.').
cargar_datos :- \+ exists_file('University.txt'), writeln('Archivo no encontrado, iniciando vacio.').

leer_lineas(Flujo) :-
    read(Flujo, Termino),
    (   Termino == end_of_file -> true
    ;   assertz(Termino),
        leer_lineas(Flujo)
    ).

% --- Persistencia: Guardar en archivo ---
guardar_datos :-
    setup_call_cleanup(
        open('University.txt', write, Flujo),
        (forall(estudiante(Id, E, S), format(Flujo, 'estudiante(~w, ~w, ~w).~n', [Id, E, S]))),
        close(Flujo)
    ).

% --- 1) Registro de Entrada (Check In) ---
registrar_entrada :-
    writeln('Ingrese el ID del estudiante:'),
    read(Id),
    (   estudiante(Id, _, 0) -> 
        writeln('Error: El estudiante ya se encuentra dentro.')
    ;   writeln('Ingrese hora de entrada (minutos desde 00:00):'),
        read(HoraEntrada),
        assertz(estudiante(Id, HoraEntrada, 0)),
        guardar_datos,
        writeln('Entrada registrada.')
    ).

% --- 2) Buscar por ID ---
buscar_estudiante :-
    writeln('Ingrese ID a buscar:'),
    read(Id),
    (   estudiante(Id, Entrada, 0) -> 
        format('Estudiante ~w presente. Ingreso en el minuto ~w.~n', [Id, Entrada])
    ;   writeln('Estudiante no encontrado o ya salio.')
    ).

% --- 5) Registro de Salida (Check Out) ---
registrar_salida :-
    writeln('Ingrese ID para salida:'),
    read(Id),
    (   retract(estudiante(Id, Entrada, 0)) ->
        writeln('Ingrese hora de salida (minutos desde 00:00):'),
        read(HoraSalida),
        assertz(estudiante(Id, Entrada, HoraSalida)),
        guardar_datos,
        calcular_tiempo(Entrada, HoraSalida, Duracion),
        format('Salida registrada. Tiempo en la universidad: ~w minutos.~n', [Duracion])
    ;   writeln('Error: ID no encontrado o ya proceso su salida.')
    ).

% --- 3) Calculo de Tiempo ---
calcular_tiempo(E, S, T) :- T is S - E.

% --- 4) Listar estudiantes ---
listar_estudiantes :-
    writeln('--- LISTA DE ESTUDIANTES EN MEMORIA ---'),
    forall(estudiante(Id, E, S), format('ID: ~w | Entrada: ~w | Salida: ~w~n', [Id, E, S])).

% --- Menu Principal ---
menu :-
    cargar_datos,
    repeat,
    nl, writeln('--- SISTEMA DE REGISTRO UNIVERSITY (PROLOG) ---'),
    writeln('1. Registrar Entrada (Check In)'),
    writeln('2. Buscar Estudiante por ID'),
    writeln('3. Registrar Salida (Check Out)'),
    writeln('4. Listar Estudiantes (Cargar de archivo)'),
    writeln('5. Salir'),
    read(Opcion),
    ejecutar(Opcion),
    Opcion == 5, !.

ejecutar(1) :- registrar_entrada.
ejecutar(2) :- buscar_estudiante.
ejecutar(3) :- registrar_salida.
ejecutar(4) :- listar_estudiantes.
ejecutar(5) :- writeln('Saliendo del sistema...').
ejecutar(_) :- writeln('Opcion no valida.');

:- initialization(menu).