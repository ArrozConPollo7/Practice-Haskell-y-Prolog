import System.IO
import Data.List

-- Estructura de datos para el estudiante [cite: 40, 92]
data Estudiante = Estudiante {
    idEst     :: String,
    [cite_start]entrada   :: Int,    -- Tiempo en minutos desde 00:00 [cite: 55]
    [cite_start]salida    :: Int     -- -1 si aún está en la universidad [cite: 18, 19]
} deriving (Show, Read)

archivoDatos = "University.txt"

-- 1) Check In: Registrar entrada [cite: 13, 14]
registrarEntrada :: String -> Int -> [Estudiante] -> [Estudiante]
registrarEntrada id hEntrada lista = Estudiante id hEntrada (-1) : lista

-- 2) Search by Student ID [cite: 17, 87]
buscarEstudiante :: String -> [Estudiante] -> IO ()
buscarEstudiante id lista = do
    let resultado = find (\e -> idEst e == id && salida e == -1) lista
    case resultado of
        Just e  -> putStrLn $ "Estudiante en campus. Entrada: " ++ show (entrada e) ++ " min." [cite: 18]
        Nothing -> putStrLn "Error: Estudiante no encontrado o ya salio." [cite: 19]

-- 3) Time Calculation [cite: 20, 21, 23]
formatearTiempo :: Int -> String
formatearTiempo totalMinutos = 
    let horas = totalMinutos `div` 60
        mins = totalMinutos `mod` 60
    in show horas ++ "h " ++ show mins ++ "m"

-- 4) Students List: Cargar y mostrar [cite: 24, 28, 89]
listarEstudiantes :: [Estudiante] -> IO ()
listarEstudiantes [] = putStrLn "La lista esta vacia."
listarEstudiantes lista = mapM_ (\e -> putStrLn $ "ID: " ++ idEst e ++ " | In: " ++ show (entrada e) ++ " | Out: " ++ show (salida e)) lista

-- 5) Check Out: Registrar salida [cite: 29, 30, 35]
registrarSalida :: String -> Int -> [Estudiante] -> [Estudiante]
registrarSalida id hSalida lista = 
    map (\e -> if idEst e == id && salida e == -1 then e { salida = hSalida } else e) lista

-- Gestión de Archivos Nativa [cite: 42, 49]
guardarArchivo :: [Estudiante] -> IO ()
guardarArchivo lista = do
    writeFile archivoDatos (unlines (map show lista)) [cite: 44]

cargarArchivo :: IO [Estudiante]
cargarArchivo = do
    -- Intentamos abrir el archivo; si no existe, retornamos lista vacía
    contenido <- readFile archivoDatos `catch` (\_ -> return "")
    -- Forzamos la lectura de la longitud para evitar errores de archivo abierto (Lazy IO)
    if length contenido >= 0 
        then return (map read (lines contenido))
        else return []

-- Menú Principal [cite: 11]
menu :: IO ()
menu = do
    lista <- cargarArchivo [cite: 43]
    putStrLn "\n--- REGISTRO UNIVERSITARIO (HASKELL) ---"
    putStrLn "1. Check In"
    putStrLn "2. Search by ID"
    putStrLn "3. List Students"
    putStrLn "4. Check Out"
    putStrLn "5. Exit"
    putStr "Opcion: "
    opcion <- getLine
    
    case opcion of
        "1" -> do
            putStr "ID: "
            id <- getLine
            putStr "Hora entrada (minutos): "
            t <- getLine
            let nuevaLista = registrarEntrada id (read t) lista
            guardarArchivo nuevaLista [cite: 44]
            menu
        "2" -> do
            putStr "ID a buscar: "
            id <- getLine
            buscarEstudiante id lista
            menu
        "3" -> do
            listarEstudiantes lista
            menu
        "4" -> do
            putStr "ID para salida: "
            id <- getLine
            putStr "Hora salida (minutos): "
            t <- getLine
            let est = find (\e -> idEst e == id && salida e == -1) lista
            case est of
                Just e -> do
                    let sTime = read t
                    putStrLn $ "Tiempo en la U: " ++ formatearTiempo (sTime - entrada e) [cite: 21, 23]
                    guardarArchivo (registrarSalida id sTime lista) [cite: 44]
                Nothing -> putStrLn "No encontrado."
            menu
        "5" -> putStrLn "Saliendo..."
        _   -> menu

main = menu