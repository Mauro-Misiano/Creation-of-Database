-- Crear la base de datos
CREATE DATABASE UniversidadLaMatanza;
GO

-- Usar la base de datos
USE UniversidadLaMatanza;
GO

-- Crear la tabla de Estudiantes
CREATE TABLE Estudiantes (
    id_estudiante INT PRIMARY KEY,
    nombre NVARCHAR(100),
    apellido NVARCHAR(100),
    edad INT,
    sexo NVARCHAR(10),
    carrera NVARCHAR(50),
    ciudad NVARCHAR(100),
    pais NVARCHAR(100)
);
GO

-- Crear la tabla de Profesores
CREATE TABLE Profesores (
    id_profesor INT PRIMARY KEY,
    nombre NVARCHAR(100),
    apellido NVARCHAR(100),
    edad INT,
    sexo NVARCHAR(10),
    departamento NVARCHAR(50),
    ciudad NVARCHAR(100),
    pais NVARCHAR(100)
);
GO

-- Crear la tabla de Cursos
CREATE TABLE Cursos (
    id_curso INT PRIMARY KEY,
    nombre NVARCHAR(100),
    departamento NVARCHAR(50),
    horas_semanales INT
);
GO

-- Crear la tabla de Calificaciones
CREATE TABLE Calificaciones (
    id_calificacion INT PRIMARY KEY,
    id_estudiante INT,
    id_profesor INT,
    id_curso INT,
    calificacion DECIMAL(3, 2),
    fecha DATE,
    FOREIGN KEY (id_estudiante) REFERENCES Estudiantes(id_estudiante),
    FOREIGN KEY (id_profesor) REFERENCES Profesores(id_profesor),
    FOREIGN KEY (id_curso) REFERENCES Cursos(id_curso)
);
GO

	-- Cargar datos de Estudiantes
INSERT INTO Estudiantes (id_estudiante, nombre, apellido, edad, sexo, carrera, ciudad, pais)
SELECT 
    JSON_VALUE(est.value, '$.id_estudiante') AS id_estudiante,
    JSON_VALUE(est.value, '$.nombre') AS nombre,
    JSON_VALUE(est.value, '$.apellido') AS apellido,
    JSON_VALUE(est.value, '$.edad') AS edad,
    JSON_VALUE(est.value, '$.sexo') AS sexo,
    JSON_VALUE(est.value, '$.carrera') AS carrera,
    JSON_VALUE(est.value, '$.ciudad') AS ciudad,
    JSON_VALUE(est.value, '$.pais') AS pais
FROM 
    OPENROWSET(BULK 'C:\Users\HP\Desktop\Posgrado\Topicos de Bases de Datos\TP Final Tecnico\universidad.json', SINGLE_CLOB) AS j -- Lee el archivo JSON como una sola cadena de texto
    CROSS APPLY OPENJSON(j.BulkColumn, '$.dimensiones.estudiantes') AS est; -- Aplica OPENJSON para extraer los datos de la sección 'estudiantes'

-- Cargar datos de Profesores
INSERT INTO Profesores (id_profesor, nombre, apellido, edad, sexo, departamento, ciudad, pais)
SELECT 
    JSON_VALUE(prof.value, '$.id_profesor') AS id_profesor,
    JSON_VALUE(prof.value, '$.nombre') AS nombre,
    JSON_VALUE(prof.value, '$.apellido') AS apellido,
    JSON_VALUE(prof.value, '$.edad') AS edad,
    JSON_VALUE(prof.value, '$.sexo') AS sexo,
    JSON_VALUE(prof.value, '$.departamento') AS departamento,
    JSON_VALUE(prof.value, '$.ciudad') AS ciudad,
    JSON_VALUE(prof.value, '$.pais') AS pais
FROM 
    OPENROWSET(BULK 'C:\Users\HP\Desktop\Posgrado\Topicos de Bases de Datos\TP Final Tecnico\universidad.json', SINGLE_CLOB) AS j
    CROSS APPLY OPENJSON(j.BulkColumn, '$.dimensiones.profesores') AS prof;

-- Cargar datos de Cursos
INSERT INTO Cursos (id_curso, nombre, departamento, horas_semanales)
SELECT 
    JSON_VALUE(cur.value, '$.id_curso') AS id_curso,
    JSON_VALUE(cur.value, '$.nombre') AS nombre,
    JSON_VALUE(cur.value, '$.departamento') AS departamento,
    JSON_VALUE(cur.value, '$.horas_semanales') AS horas_semanales
FROM 
    OPENROWSET(BULK 'C:\Users\HP\Desktop\Posgrado\Topicos de Bases de Datos\TP Final Tecnico\universidad.json', SINGLE_CLOB) AS j
    CROSS APPLY OPENJSON(j.BulkColumn, '$.dimensiones.cursos') AS cur;

-- Cargar datos de Calificaciones
INSERT INTO Calificaciones (id_calificacion, id_estudiante, id_profesor, id_curso, calificacion, fecha)
SELECT 
    JSON_VALUE(cal.value, '$.id_calificacion') AS id_calificacion,
    JSON_VALUE(cal.value, '$.id_estudiante') AS id_estudiante,
    JSON_VALUE(cal.value, '$.id_profesor') AS id_profesor,
    JSON_VALUE(cal.value, '$.id_curso') AS id_curso,
    JSON_VALUE(cal.value, '$.calificacion') AS calificacion,
    JSON_VALUE(cal.value, '$.fecha') AS fecha
FROM 
    OPENROWSET(BULK 'C:\Users\HP\Desktop\Posgrado\Topicos de Bases de Datos\TP Final Tecnico\universidad.json', SINGLE_CLOB) AS j
    CROSS APPLY OPENJSON(j.BulkColumn, '$.hechos.calificaciones') AS cal;

	-- Verificación de los datos

	SELECT TOP (10) *
	FROM Estudiantes;

	SELECT TOP (10) *
	FROM Profesores;

	SELECT TOP (10) *
	FROM Cursos;

	SELECT TOP (10) *
	FROM Calificaciones;

-- SP que calcula el promedio de notas por estudiante

	CREATE PROCEDURE CalcularPromedioNotas
    @id_estudiante INT  -- Parámetro de entrada: ID del estudiante
AS
BEGIN
    -- Selecciona el promedio de las calificaciones del estudiante
    SELECT 
        @id_estudiante AS id_estudiante,
        AVG(cal.calificacion) AS promedio_calificaciones  -- Calcula el promedio de las calificaciones
    FROM 
        Calificaciones cal
    WHERE 
        cal.id_estudiante = @id_estudiante  -- Filtra por el ID del estudiante proporcionado
END

-- Ejecución del SP

EXECUTE CalcularPromedioNotas @id_estudiante = 1;

-- Verificación

SELECT 
	id_estudiante, AVG(cal.calificacion) AS promedio_calificaciones
FROM 
	Calificaciones cal
WHERE 
	id_estudiante = 1
GROUP BY 
	id_estudiante;

-- SP para consultar las materias inscriptas por estudiante

CREATE PROCEDURE ObtenerMateriasInscripcion
    @id_estudiante INT  -- Parámetro de entrada: ID del estudiante
AS
BEGIN
    -- Selecciona los cursos en los que está inscrito el estudiante
    SELECT 
        cur.id_curso, 
        cur.nombre AS nombre_curso,
        cur.departamento,
        cur.horas_semanales
    FROM 
        Calificaciones cal
    INNER JOIN 
        Cursos cur ON cal.id_curso = cur.id_curso  -- Une con la tabla Cursos para obtener detalles del curso
    WHERE 
        cal.id_estudiante = @id_estudiante  -- Filtra por el ID del estudiante proporcionado
END

-- Ejecución del SP

EXEC ObtenerMateriasInscripcion @id_estudiante = 1;

-- Verificacion

SELECT 
        cur.id_curso, 
        cur.nombre AS nombre_curso,
        cur.departamento,
        cur.horas_semanales
    FROM 
        Calificaciones cal
    INNER JOIN 
        Cursos cur ON cal.id_curso = cur.id_curso  
    WHERE 
        cal.id_estudiante = 1;

-- Se crea un Triggers para alojar en un nuevo campo de la tabla calificaciones, un "aprobado"
-- en los casos en donde la calificacion sea mayor o igual a 7, o "desaprobado" para los casos
-- que no cumplan la condición.

ALTER TABLE Calificaciones
ADD Aprobado NVARCHAR(20);  -- Agrega el campo 'Aprobado', usando NVARCHAR para texto

CREATE TRIGGER trg_ActualizarAprobado
ON Calificaciones
AFTER INSERT
AS
BEGIN
    -- Actualiza el campo 'Aprobado' basado en el valor de la calificación insertada
    UPDATE Calificaciones
    SET Aprobado = 
        CASE
            WHEN i.calificacion >= 7 THEN 'Aprobado'  -- Inserta Aprobado
            ELSE 'No Aprobado'  -- Inserta No Aprobado
        END
    FROM 
        Calificaciones c
    INNER JOIN 
        inserted i ON c.id_calificacion = i.id_calificacion;  -- Une con la tabla 'inserted' para acceder a los datos insertados. Es una tabla especial 
															  -- que contiene las filas que se acaban de insertar
END

-- Prueba del Triggers
-- Insertar otra calificación para probar el trigger
INSERT INTO Calificaciones (id_calificacion, id_estudiante, id_profesor, id_curso, calificacion, fecha)
VALUES (501, 1, 1, 1, 6, GETDATE());  -- Calificación de 6, que debería ser '❌ No Aprobado'

-- Insertar una nueva calificación para probar el trigger
INSERT INTO Calificaciones (id_calificacion, id_estudiante, id_profesor, id_curso, calificacion, fecha)
VALUES (502, 1, 1, 1, 8, GETDATE());  -- Calificación de 8, que debería ser '✅ Aprobado'

-- Verificacion: 

SELECT 
	*
FROM 
	Calificaciones
WHERE 
	id_calificacion IN (501,502);

-- Se crea una vista que informa un TOP 10 de los docentes que tienen más cursos a cargo.

CREATE VIEW Top10DocentesConMasCursos AS
SELECT 
	TOP (10)
    p.nombre AS Nombre_Docente,           
    p.apellido AS Apellido_Docente,      
    COUNT(c.id_curso) AS Cantidad_Cursos  
FROM 
    Profesores p
INNER JOIN 
    Calificaciones cal ON p.id_profesor = cal.id_profesor  
INNER JOIN 
    Cursos c ON cal.id_curso = c.id_curso  
GROUP BY 
    p.id_profesor, p.nombre, p.apellido  
ORDER BY 
    Cantidad_Cursos DESC;

-- Consulta de la Vista

SELECT *
FROM Top10DocentesConMasCursos;



