% ============================================================
%  SISTEMA DE REGISTRO UNIVERSITARIO - PROLOG
%  ST0244 - Programming Languages - EAFIT University
% ============================================================

:- dynamic estudiante/3. % estudiante(ID, HoraEntrada, HoraSalida) — 0 si no ha salido

% ============================================================
%  CARGA Y PERSISTENCIA
% ============================================================

cargar_datos :-
    retractall(estudiante(_, _, _)),
    (   exists_file('University.txt')
    ->  setup_call_cleanup(
            open('University.txt', read, Flujo),
            leer_lineas(Flujo),
            close(Flujo)
        ),
        writeln('Datos cargados exitosamente.')
    ;   writeln('Archivo no encontrado, iniciando vacio.')
    ).

leer_lineas(Flujo) :-
    catch(
        (   read(Flujo, Termino),
            (   Termino == end_of_file
            ->  true
            ;   assertz(Termino),
                leer_lineas(Flujo)
            )
        ),
        _Error,
        (writeln('Advertencia: linea invalida en el archivo, se ignora.'),
        leer_lineas(Flujo))
    ).

guardar_datos :-
    setup_call_cleanup(
        open('University.txt', write, Flujo),
        forall(
            estudiante(Id, E, S),
            format(Flujo, 'estudiante(~w, ~w, ~w).~n', [Id, E, S])
        ),
        close(Flujo)
    ).

% ============================================================
%  1) REGISTRO DE ENTRADA (CHECK IN)
% ============================================================

registrar_entrada :-
    writeln('Ingrese el ID del estudiante:'),
    read(Id),
    (   \+ integer(Id)
    ->  writeln('Error: el ID debe ser un numero entero.')
    ;   estudiante(Id, _, 0)
    ->  writeln('Error: el estudiante ya se encuentra dentro.')
    ;   writeln('Ingrese hora de entrada en formato HH:MM (entre comillas simples, ej: \'08:30\'):'),
        read(HoraStr),
        (   parsear_hora(HoraStr, Minutos)
        ->  assertz(estudiante(Id, Minutos, 0)),
            guardar_datos,
            format('Entrada registrada. ID: ~w | Hora: ~w (~w minutos desde 00:00).~n',
                    [Id, HoraStr, Minutos])
        ;   writeln('Error: formato de hora invalido. Use HH:MM entre comillas simples.')
        )
    ).

% ============================================================
%  2) BUSCAR ESTUDIANTE POR ID
% ============================================================

buscar_estudiante :-
    writeln('Ingrese ID a buscar:'),
    read(Id),
    (   estudiante(Id, Entrada, 0)
    ->  minutos_a_hora(Entrada, HoraStr),
        format('Estudiante ~w esta DENTRO. Ingreso a las ~w.~n', [Id, HoraStr])
    ;   estudiante(Id, Entrada, Salida)
    ->  minutos_a_hora(Entrada, EntradaStr),
        minutos_a_hora(Salida, SalidaStr),
        calcular_tiempo(Entrada, Salida, Duracion),
        format('Estudiante ~w ya SALIO. Entrada: ~w | Salida: ~w | Tiempo: ~w minutos.~n',
                [Id, EntradaStr, SalidaStr, Duracion])
    ;   format('Estudiante con ID ~w no encontrado.~n', [Id])
    ).

% ============================================================
%  3) CALCULO DE TIEMPO
% ============================================================

calcular_tiempo(Entrada, Salida, Duracion) :-
    Duracion is Salida - Entrada.

% ============================================================
%  4) LISTAR ESTUDIANTES (CARGAR DESDE ARCHIVO)
% ============================================================

listar_estudiantes :-
    cargar_datos,
    writeln('--- LISTA DE ESTUDIANTES ---'),
    (   \+ estudiante(_, _, _)
    ->  writeln('No hay estudiantes registrados.')
    ;   forall(
            estudiante(Id, E, S),
            (   minutos_a_hora(E, EntradaStr),
                (   S =:= 0
                ->  format('ID: ~w | Entrada: ~w | Salida: DENTRO~n', [Id, EntradaStr])
                ;   minutos_a_hora(S, SalidaStr),
                    calcular_tiempo(E, S, Dur),
                    format('ID: ~w | Entrada: ~w | Salida: ~w | Tiempo: ~w min~n',
                            [Id, EntradaStr, SalidaStr, Dur])
                )
            )
        )
    ).

% ============================================================
%  5) REGISTRO DE SALIDA (CHECK OUT)
% ============================================================

registrar_salida :-
    writeln('Ingrese ID para salida:'),
    read(Id),
    (   retract(estudiante(Id, Entrada, 0))
    ->  writeln('Ingrese hora de salida en formato HH:MM (ej: \'17:45\'):'),
        read(HoraStr),
        (   parsear_hora(HoraStr, MinutosSalida)
        ->  (   MinutosSalida >= Entrada
            ->  assertz(estudiante(Id, Entrada, MinutosSalida)),
                guardar_datos,
                calcular_tiempo(Entrada, MinutosSalida, Duracion),
                minutos_a_hora(Entrada, EntStr),
                minutos_a_hora(MinutosSalida, SalStr),
                format('Salida registrada. ID: ~w | Entrada: ~w | Salida: ~w | Tiempo: ~w minutos.~n',
                        [Id, EntStr, SalStr, Duracion])
            ;   assertz(estudiante(Id, Entrada, 0)),
                writeln('Error: la hora de salida no puede ser anterior a la de entrada.')
            )
        ;   assertz(estudiante(Id, Entrada, 0)),
            writeln('Error: formato de hora invalido. Use HH:MM entre comillas simples.')
        )
    ;   writeln('Error: ID no encontrado o el estudiante ya proceso su salida.')
    ).

% ============================================================
%  UTILIDADES DE HORA
% ============================================================

% parsear_hora(+HoraStr, -Minutos)
% Convierte 'HH:MM' a minutos desde 00:00
parsear_hora(HoraStr, Minutos) :-
    atom(HoraStr),
    atom_string(HoraStr, Str),
    split_string(Str, ":", "", Partes),
    Partes = [HH, MM | _],
    number_string(H, HH),
    number_string(M, MM),
    integer(H), integer(M),
    H >= 0, H =< 23,
    M >= 0, M =< 59,
    Minutos is H * 60 + M.

% minutos_a_hora(+Minutos, -HoraStr)
% Convierte minutos desde 00:00 a formato 'HH:MM'
minutos_a_hora(Minutos, HoraStr) :-
    H is Minutos // 60,
    M is Minutos mod 60,
    (H < 10 -> format(atom(HH), '0~d', [H]) ; format(atom(HH), '~d', [H])),
    (M < 10 -> format(atom(MM), '0~d', [M]) ; format(atom(MM), '~d', [M])),
    atomic_list_concat([HH, ':', MM], HoraStr).

% ============================================================
%  MENU PRINCIPAL
% ============================================================

menu :-
    cargar_datos,
    menu_loop.

menu_loop :-
    nl,
    writeln('========================================'),
    writeln('  SISTEMA DE REGISTRO UNIVERSITARIO'),
    writeln('========================================'),
    writeln('  1. Check In  (Registrar Entrada)'),
    writeln('  2. Buscar Estudiante por ID'),
    writeln('  3. Check Out (Registrar Salida)'),
    writeln('  4. Listar Estudiantes (desde archivo)'),
    writeln('  5. Salir'),
    writeln('========================================'),
    write('Seleccione una opcion: '),
    read(Opcion),
    ejecutar(Opcion).

ejecutar(1) :- registrar_entrada, menu_loop.
ejecutar(2) :- buscar_estudiante,  menu_loop.
ejecutar(3) :- registrar_salida,   menu_loop.
ejecutar(4) :- listar_estudiantes, menu_loop.
ejecutar(5) :- writeln('Saliendo del sistema. Hasta luego.').
ejecutar(_) :- writeln('Opcion no valida. Intente de nuevo.'), menu_loop.

:- initialization(menu, main).
