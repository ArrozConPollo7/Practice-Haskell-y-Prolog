import System.IO
import Data.List

-- Estructura de datos para el estudiante
data Estudiante = Estudiante {
    idEst     :: String,entrada   :: Int,    -- Tiempo en minutos desde 00:00salida    :: Int     -- -1 si aún está en la universidad
} deriving (Show, Read)

archivoDatos = "University.txt"

-- 1) Check In: Registrar entrada
registrarEntrada :: String -> Int -> [Estudiante] -> [Estudiante]
registrarEntrada id hEntrada lista = Estudiante id hEntrada (-1) : lista

-- 2) Search by Student ID
buscarEstudiante :: String -> [Estudiante] -> IO ()
buscarEstudiante id lista = do
    let resultado = find (\e -> idEst e == id && salida e == -1) lista
    case resultado of
        Just e  -> putStrLn $ "Estudiante en campus. Entrada: " ++ show (entrada e) ++ " min."
        Nothing -> putStrLn "Error: Estudiante no encontrado o ya salio."

-- 3) Time Calculation
formatearTiempo :: Int -> String
formatearTiempo totalMinutos = 
    let horas = totalMinutos `div` 60
        mins = totalMinutos `mod` 60
    in show horas ++ "h " ++ show mins ++ "m"

-- 4) Students List: Cargar y mostrar
listarEstudiantes :: [Estudiante] -> IO ()
listarEstudiantes [] = putStrLn "La lista esta vacia."
listarEstudiantes lista = mapM_ (\e -> putStrLn $ "ID: " ++ idEst e ++ " | In: " ++ show (entrada e) ++ " | Out: " ++ show (salida e)) lista

-- 5) Check Out: Registrar salida
registrarSalida :: String -> Int -> [Estudiante] -> [Estudiante]
registrarSalida id hSalida lista = 
    map (\e -> if idEst e == id && salida e == -1 then e { salida = hSalida } else e) lista

-- Gestión de Archivos Nativa
guardarArchivo :: [Estudiante] -> IO ()
guardarArchivo lista = do
    writeFile archivoDatos (unlines (map show lista))

cargarArchivo :: IO [Estudiante]
cargarArchivo = do
    -- Intentamos abrir el archivo; si no existe, retornamos lista vacía
    contenido <- readFile archivoDatos `catch` (\_ -> return "")
    -- Forzamos la lectura de la longitud para evitar errores de archivo abierto (Lazy IO)
    if length contenido >= 0 
        then return (map read (lines contenido))
        else return []

-- Menú Principal
menu :: IO ()
menu = do
    lista <- cargarArchivo
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
            guardarArchivo nuevaLista
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
                    putStrLn $ "Tiempo en la U: " ++ formatearTiempo (sTime - entrada e)
                    guardarArchivo (registrarSalida id sTime lista)
                Nothing -> putStrLn "No encontrado."
            menu
        "5" -> putStrLn "Saliendo..."
        _   -> menu

main = menu