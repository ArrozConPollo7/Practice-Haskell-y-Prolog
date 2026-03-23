import System.IO
import System.Directory (doesFileExist)
import Data.List
import Control.Exception
import Data.Char (isDigit)

-- Definición del tipo de dato Estudiante
data Estudiante = Estudiante {
    idEst   :: String,
    entrada :: Int,    -- Minutos desde 00:00
    salida  :: Int     -- -1 si aún está en campus
} deriving (Show, Read)

archivoDatos :: String
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

-- Convierte minutos a "HH:MM" para mostrar
minutosAHora :: Int -> String
minutosAHora m =
    let h   = m `div` 60
        mn  = m `mod` 60
        pad n = if n < 10 then "0" ++ show n else show n
    in pad h ++ ":" ++ pad mn

-- Formatea una duración en minutos como "HH:MM hs"
formatearTiempo :: Int -> String
formatearTiempo totalMinutos =
    let horas = totalMinutos `div` 60
        mins  = totalMinutos `mod` 60
        pad n = if n < 10 then "0" ++ show n else show n
    in pad horas ++ ":" ++ pad mins ++ " hs"

-- Alinea un string a la izquierda con padding
padR :: Int -> String -> String
padR n s = take n (s ++ repeat ' ')

-- ─────────────────────────────────────────
-- PERSISTENCIA
-- ─────────────────────────────────────────

-- Guarda la lista en University.txt
guardarArchivo :: [Estudiante] -> IO ()
guardarArchivo lista = writeFile archivoDatos (unlines (map show lista))

-- Carga University.txt; si no existe lo crea vacío
cargarArchivo :: IO [Estudiante]
cargarArchivo = do
    existe <- doesFileExist archivoDatos
    if not existe
        then do
            writeFile archivoDatos ""
            putStrLn "  [INFO] University.txt no encontrado. Se creo uno nuevo."
            return []
        else do
            contenido <- readFile archivoDatos
            let lineas = filter (not . null) (lines contenido)
            return (map read lineas)

-- ─────────────────────────────────────────
-- 1) CHECK IN
-- ─────────────────────────────────────────
-- Registra la entrada de un estudiante.
-- Verifica que no esté ya dentro antes de agregar.
checkIn :: [Estudiante] -> IO [Estudiante]
checkIn lista = do
    putStr "  ID del estudiante: "
    hFlush stdout
    id <- getLine
    case find (\e -> idEst e == id && salida e == -1) lista of
        Just _  -> do
            putStrLn "  [!] El estudiante ya se encuentra dentro del campus."
            return lista
        Nothing -> do
            t <- pedirHora "  Hora de entrada (HH:MM): "
            let nuevaLista = Estudiante id t (-1) : lista
            guardarArchivo nuevaLista
            putStrLn $ "  [OK] Check-in registrado a las " ++ minutosAHora t
            return nuevaLista

-- ─────────────────────────────────────────
-- 2) SEARCH BY STUDENT ID
-- ─────────────────────────────────────────
-- Busca un estudiante actualmente en campus por su ID.
searchByID :: [Estudiante] -> IO ()
searchByID lista = do
    putStr "  ID a buscar: "
    hFlush stdout
    id <- getLine
    case find (\e -> idEst e == id && salida e == -1) lista of
        Just e  -> do
            putStrLn "  +---------------------------+"
            putStrLn $ "  | ID      : " ++ idEst e
            putStrLn $ "  | Entrada : " ++ minutosAHora (entrada e)
            putStrLn   "  | Estado  : EN CAMPUS"
            putStrLn   "  +---------------------------+"
        Nothing -> putStrLn "  [!] Estudiante no encontrado o ya salio."

-- ─────────────────────────────────────────
-- 3) TIME CALCULATION
-- ─────────────────────────────────────────
-- Calcula y muestra el tiempo que un estudiante
-- estuvo en la universidad (requiere Check Out previo).
timeCalculation :: [Estudiante] -> IO ()
timeCalculation lista = do
    putStr "  ID del estudiante: "
    hFlush stdout
    id <- getLine
    case find (\e -> idEst e == id) lista of
        Nothing -> putStrLn "  [!] No se encontro ningun registro para ese ID."
        Just e  ->
            if salida e == -1
                then putStrLn "  [!] El estudiante aun esta en campus. Realice el Check Out primero."
                else do
                    let duracion = salida e - entrada e
                    putStrLn "  +---------------------------+"
                    putStrLn $ "  | ID      : " ++ idEst e
                    putStrLn $ "  | Entrada : " ++ minutosAHora (entrada e)
                    putStrLn $ "  | Salida  : " ++ minutosAHora (salida e)
                    putStrLn $ "  | Tiempo  : " ++ formatearTiempo duracion
                    putStrLn   "  +---------------------------+"

-- ─────────────────────────────────────────
-- 4) STUDENTS LIST (LOAD FROM FILE)
-- ─────────────────────────────────────────
-- Carga University.txt en el momento en que se elige
-- esta opción, almacena en lista y la muestra.
studentsList :: IO [Estudiante]
studentsList = do
    putStrLn "  Cargando University.txt..."
    lista <- cargarArchivo
    if null lista
        then putStrLn "  La lista esta vacia."
        else do
            putStrLn "  ID       | Entrada | Salida  | Estado"
            putStrLn "  ---------+---------+---------+----------"
            mapM_ printFila lista
            putStrLn $ "  Total: " ++ show (length lista) ++ " registros."
    return lista
  where
    printFila e =
        let est = if salida e == -1 then "EN CAMPUS" else "SALIO"
            sal = if salida e == -1 then "  --   " else minutosAHora (salida e)
        in putStrLn $ "  " ++ padR 8 (idEst e)
                   ++ " | " ++ minutosAHora (entrada e)
                   ++ "  | " ++ sal
                   ++ "  | " ++ est

-- ─────────────────────────────────────────
-- 5) CHECK OUT
-- ─────────────────────────────────────────
-- Registra la salida de un estudiante y muestra
-- el tiempo que estuvo en la universidad.
checkOut :: [Estudiante] -> IO [Estudiante]
checkOut lista = do
    putStr "  ID del estudiante: "
    hFlush stdout
    id <- getLine
    case find (\e -> idEst e == id && salida e == -1) lista of
        Nothing -> do
            putStrLn "  [!] Estudiante no encontrado o ya realizo su salida."
            return lista
        Just e  -> do
            t <- pedirHora "  Hora de salida (HH:MM): "
            let duracion    = t - entrada e
                nuevaLista  = map (\x -> if idEst x == id && salida x == -1
                                         then x { salida = t } else x) lista
            guardarArchivo nuevaLista
            putStrLn $ "  [OK] Check-out registrado a las " ++ minutosAHora t
            putStrLn $ "  Tiempo en la universidad: " ++ formatearTiempo duracion
            return nuevaLista

-- ─────────────────────────────────────────
-- MENÚ PRINCIPAL
-- ─────────────────────────────────────────
menu :: [Estudiante] -> IO ()
menu lista = do
    putStrLn "\n==============================="
    putStrLn "  REGISTRO UNIVERSITARIO"
    putStrLn "==============================="
    putStrLn "  1. Check In"
    putStrLn "  2. Search by Student ID"
    putStrLn "  3. Time Calculation"
    putStrLn "  4. List Students (Load from File)"
    putStrLn "  5. Check Out"
    putStrLn "  6. Salir"
    putStr   "  Opcion: "
    hFlush stdout
    opcion <- getLine
    case opcion of
        "1" -> checkIn lista          >>= menu
        "2" -> searchByID lista       >>  menu lista
        "3" -> timeCalculation lista  >>  menu lista
        "4" -> studentsList           >>= menu
        "5" -> checkOut lista         >>= menu
        "6" -> putStrLn "  Hasta luego!"
        _   -> putStrLn "  Opcion no valida." >> menu lista

-- ─────────────────────────────────────────
-- MAIN
-- ─────────────────────────────────────────
main :: IO ()
main = do
    putStrLn "  Cargando University.txt..."
    lista <- cargarArchivo
    putStrLn $ "  " ++ show (length lista) ++ " registros cargados."
    menu lista
