import System.IO
import Data.List
import Control.Exception
import Data.Char (isDigit)

-- Definición del tipo de dato Estudiante
data Estudiante = Estudiante {
    idEst     :: String,
    entrada   :: Int,
    salida    :: Int
} deriving (Show, Read)

archivoDatos = "University.txt"

-- Convierte "HH:MM" a minutos totales desde medianoche
parsearHora :: String -> Maybe Int
parsearHora s = case break (== ':') s of
    (hh, ':':mm) | all isDigit hh && all isDigit mm ->
        let h = read hh; m = read mm
        in if h < 24 && m < 60 then Just (h * 60 + m) else Nothing
    _ -> Nothing

-- Pide una hora HH:MM al usuario con validación
pedirHora :: String -> IO Int
pedirHora prompt = do
    putStr prompt
    hFlush stdout
    s <- getLine
    case parsearHora s of
        Just mins -> return mins
        Nothing   -> putStrLn "  Formato invalido. Use HH:MM (ej: 08:30)" >> pedirHora prompt

-- 1) Check In: Registrar entrada [cite: 13, 14]
registrarEntrada :: String -> Int -> [Estudiante] -> [Estudiante]
registrarEntrada id hEntrada lista = Estudiante id hEntrada (-1) : lista

-- 2) Search by ID: Buscar estudiante activo
buscarEstudiante :: String -> [Estudiante] -> IO ()
buscarEstudiante id lista = do
    let resultado = find (\e -> idEst e == id && salida e == -1) lista
    case resultado of
        Just e  -> do
            putStrLn $ "  +---------------------------+"
            putStrLn $ "  | ID      : " ++ idEst e
            putStrLn $ "  | Entrada : " ++ minutosAHora (entrada e)
            putStrLn $ "  | Estado  : EN CAMPUS"
            putStrLn $ "  +---------------------------+"
        Nothing -> putStrLn "  [!] Estudiante no encontrado o ya salio."

-- 3) Time Calculation: Formatear duración en HH:MM
formatearTiempo :: Int -> String
formatearTiempo totalMinutos =
    let horas = totalMinutos `div` 60
        mins  = totalMinutos `mod` 60
        pad n = if n < 10 then "0" ++ show n else show n
    in pad horas ++ ":" ++ pad mins ++ " hs"

-- Convierte minutos a "HH:MM" para mostrar
minutosAHora :: Int -> String
minutosAHora m =
    let h   = m `div` 60
        min = m `mod` 60
        pad n = if n < 10 then "0" ++ show n else show n
    in pad h ++ ":" ++ pad min

-- 4) Students List: Cargar y mostrar
listarEstudiantes :: [Estudiante] -> IO ()
listarEstudiantes [] = putStrLn "  La lista esta vacia."
listarEstudiantes lista = do
    putStrLn "  ID       | Entrada | Salida  | Estado"
    putStrLn "  ---------+---------+---------+----------"
    mapM_ printFila lista
    putStrLn $ "  Total: " ++ show (length lista) ++ " registros."
  where
    printFila e =
        let est = if salida e == -1 then "EN CAMPUS" else "SALIO"
            sal = if salida e == -1 then "  --   " else minutosAHora (salida e)
        in putStrLn $ "  " ++ padR 8 (idEst e)
                   ++ " | " ++ minutosAHora (entrada e)
                   ++ "  | " ++ sal
                   ++ "  | " ++ est
    padR n s = take n (s ++ repeat ' ')

-- 5) Check Out: Registrar salida [cite: 29, 30, 35]
registrarSalida :: String -> Int -> [Estudiante] -> [Estudiante]
registrarSalida id hSalida lista = 
    map (\e -> if idEst e == id && salida e == -1 then e { salida = hSalida } else e) lista

-- Persistencia: Guardar en archivo [cite: 44]
guardarArchivo :: [Estudiante] -> IO ()
guardarArchivo lista = writeFile archivoDatos (unlines (map show lista))

-- Persistencia: Cargar desde archivo [cite: 43]
cargarArchivo :: IO [Estudiante]
cargarArchivo = do
    -- El catch evita que el programa falle si el archivo no existe [cite: 60]
    contenido <- readFile archivoDatos `catch` (\e -> let _ = (e :: IOError) in return "")
    if length contenido >= 0 
        then return (map read (lines contenido))
        else return []

-- 3) Time Calculation: mostrar tiempo de un estudiante
calcularTiempo :: String -> [Estudiante] -> IO ()
calcularTiempo id lista =
    case find (\e -> idEst e == id) lista of
        Nothing -> putStrLn "  [!] No se encontro ningun registro para ese ID."
        Just e  ->
            if salida e == -1
                then putStrLn "  [!] El estudiante aun esta en campus. Haz Check Out primero."
                else do
                    let duracion = salida e - entrada e
                    putStrLn $ "  +---------------------------+"
                    putStrLn $ "  | ID      : " ++ idEst e
                    putStrLn $ "  | Entrada : " ++ minutosAHora (entrada e)
                    putStrLn $ "  | Salida  : " ++ minutosAHora (salida e)
                    putStrLn $ "  | Tiempo  : " ++ formatearTiempo duracion
                    putStrLn $ "  +---------------------------+"

-- Menú Principal: recibe la lista en memoria como argumento
menu :: [Estudiante] -> IO ()
menu lista = do
    putStrLn "\n==============================="
    putStrLn "  REGISTRO UNIVERSITARIO"
    putStrLn "==============================="
    putStrLn "  1. Check In"
    putStrLn "  2. Search by Student ID"
    putStrLn "  3. Time Calculation"
    putStrLn "  4. List Students"
    putStrLn "  5. Check Out"
    putStrLn "  6. Salir"
    putStr "  Opcion: "
    hFlush stdout
    opcion <- getLine

    case opcion of
        "1" -> do
            putStr "  ID del estudiante: "
            hFlush stdout
            id <- getLine
            t <- pedirHora "  Hora de entrada (HH:MM): "
            let nuevaLista = registrarEntrada id t lista
            guardarArchivo nuevaLista
            putStrLn $ "  [OK] Check-in registrado a las " ++ minutosAHora t
            menu nuevaLista
        "2" -> do
            putStr "  ID a buscar: "
            hFlush stdout
            id <- getLine
            buscarEstudiante id lista
            menu lista
        "3" -> do
            putStr "  ID del estudiante: "
            hFlush stdout
            id <- getLine
            calcularTiempo id lista
            menu lista
        "4" -> do
            listarEstudiantes lista
            menu lista
        "5" -> do
            putStr "  ID del estudiante: "
            hFlush stdout
            id <- getLine
            let est = find (\e -> idEst e == id && salida e == -1) lista
            case est of
                Just e -> do
                    t <- pedirHora "  Hora de salida (HH:MM): "
                    let duracion = t - entrada e
                    let nuevaLista = registrarSalida id t lista
                    putStrLn $ "  [OK] Check-out a las " ++ minutosAHora t
                    putStrLn $ "  Tiempo en la U: " ++ formatearTiempo duracion
                    guardarArchivo nuevaLista
                    menu nuevaLista
                Nothing -> do
                    putStrLn "  [!] No encontrado o ya salio."
                    menu lista
        "6" -> putStrLn "  Hasta luego!"
        _   -> menu lista

-- Punto de entrada: carga University.txt una sola vez y arranca el loop
main :: IO ()
main = do
    putStrLn "  Cargando University.txt..."
    lista <- cargarArchivo
    putStrLn $ "  " ++ show (length lista) ++ " registros cargados."
    menu lista