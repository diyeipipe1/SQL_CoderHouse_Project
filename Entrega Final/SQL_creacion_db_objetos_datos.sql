-- -- -- -- -- -- -- -- -- -- -CREACIÓN DE TABLAS- -- -- -- -- -- -- -- -- -- --

CREATE DATABASE IF NOT EXISTS ciudadela_universitaria;

USE ciudadela_universitaria;


CREATE TABLE IF NOT EXISTS residentes(
	resident_id INT NOT NULL UNIQUE PRIMARY KEY,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    fecha_nacimiento DATE NOT NULL,
    nombres VARCHAR(50) NOT NULL,
    apellidos VARCHAR(50) NOT NULL, 
    numero VARCHAR(20) NOT NULL,
    correo VARCHAR(50) NOT NULL, 
    universidad VARCHAR(50) NOT NULL,
    programa VARCHAR(50) NOT NULL,
    locacion VARCHAR(50) NOT NULL,
    sexo VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS mentores(
	mentor_id INT NOT NULL UNIQUE PRIMARY KEY,
	nombres VARCHAR(50) NOT NULL,
    apellidos VARCHAR(50) NOT NULL, 
    numero VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS mesa(
	mesa_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    mesa_descripcion VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS  anotaciones(
	anotacion_id INT NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
    resident_id INT NOT NULL,
    gravedad INT NOT NULL,
    descripcion VARCHAR(250) NOT NULL,
    mentor_id INT NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (resident_id)
		REFERENCES residentes(resident_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (mentor_id)
		REFERENCES mentores(mentor_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS base_actual(
	resident_id INT NOT NULL UNIQUE,
    apto_code VARCHAR(6) NOT NULL UNIQUE,
    llegada_fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    mentor_id INT NOT NULL,
    uso_imagen BOOL NOT NULL DEFAULT FALSE,
    FOREIGN KEY (resident_id)
		REFERENCES residentes(resident_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (mentor_id)
		REFERENCES mentores(mentor_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS acomodacion(
	acomoda_id VARCHAR(5) NOT NULL UNIQUE PRIMARY KEY,
    num_cuartos INT NOT NULL,
    num_banios INT NOT NULL,
    sofa BOOL NOT NULL DEFAULT FALSE,
    mesa_id INT NOT NULL DEFAULT 0, 
    descripcion VARCHAR(100) NOT NULL,
    totales INT NOT NULL,
    FOREIGN KEY (mesa_id)
		REFERENCES mesa(mesa_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);	

CREATE TABLE IF NOT EXISTS encuesta(
	encuesta_id INT NOT NULL UNIQUE AUTO_INCREMENT PRIMARY KEY,
    satis_mentores INT NOT NULL DEFAULT 0,
    satis_limpieza INT NOT NULL DEFAULT 0,
    satis_servicios INT NOT NULL DEFAULT 0,
    satis_apto INT NOT NULL DEFAULT 0,
    satis_instalacion INT NOT NULL DEFAULT 0,
    satis_eventos INT NOT NULL DEFAULT 0,
    satis_gestion INT NOT NULL DEFAULT 0,
    anadicion VARCHAR(250)
);

CREATE TABLE IF NOT EXISTS leads(
	lead_id INT NOT NULL UNIQUE PRIMARY KEY,
    contract_id INT UNIQUE,
    red_social VARCHAR(50),
    telefono VARCHAR(20),
    correo VARCHAR(50),
    instagram BOOL NOT NULL DEFAULT FALSE,
    facebook BOOL NOT NULL DEFAULT FALSE,
    whatsapp BOOL NOT NULL DEFAULT FALSE,
    anotados_eventos BOOL NOT NULL DEFAULT FALSE,
    google_ad BOOL NOT NULL DEFAULT FALSE,
    pagina_web BOOL NOT NULL DEFAULT FALSE,
    alterno_contacto VARCHAR(50),
    first_approach BOOL NOT NULL DEFAULT FALSE,
    interes BOOL
);

CREATE TABLE IF NOT EXISTS contratos(
	contract_id INT NOT NULL UNIQUE PRIMARY KEY AUTO_INCREMENT,
    resident_id INT NOT NULL,
    encuesta_id INT NOT NULL UNIQUE,
    acomoda_id VARCHAR(5) NOT NULL,
    lead_id INT,
    duracion VARCHAR(50) NOT NULL,
    nivel VARCHAR(50) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_end DATE NOT NULL,
    valor INT NOT NULL,
    semestre INT NOT NULL,
    enviado BOOL NOT NULL DEFAULT FALSE,
    firmado BOOL NOT NULL DEFAULT FALSE,
    contado BOOL NOT NULL DEFAULT FALSE,
    manual BOOL NOT NULL DEFAULT FALSE,
    eps VARCHAR(50) NOT NULL,
    numero_responsable VARCHAR(20) NOT NULL,
    responsable VARCHAR (50) NOT NULL,
    anotaciones VARCHAR(250) NOT NULL,
    FOREIGN KEY (resident_id)
		REFERENCES residentes(resident_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
	FOREIGN KEY (encuesta_id)
		REFERENCES encuesta(encuesta_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (acomoda_id)
		REFERENCES acomodacion(acomoda_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS log_contratos(
	contract_id INT NOT NULL UNIQUE,
    usuario VARCHAR(100) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS log_residente(
	resident_id INT NOT NULL UNIQUE,
    usuario VARCHAR(100) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
);



-- -- -- -- -- -- -- -- -- -- -CREACIÓN DE VISTAS- -- -- -- -- -- -- -- -- -- --
/*
	Como los datos de los residentes se encuentran en una tabla diferente a la que tiene los
	datos de sus viviendas y mentores en el semestre, se juntan estas dos para tener la info de cada
	residente durante el actual semestre
*/
CREATE VIEW vbase_datos_lookat AS
	SELECT CONCAT(r.nombres,' ',r.apellidos) AS nombre_completo, r.fecha_nacimiento, r.numero, correo, universidad, 
    ba.resident_id, ba.apto_code, CONCAT(m.nombres, ' ',m.apellidos) AS mentor, ba.uso_imagen
	FROM base_actual as ba 
	LEFT JOIN residentes as r ON ba.resident_id = r.resident_id
	LEFT JOIN mentores as m ON ba.mentor_id = m.mentor_id
	ORDER BY nombre_completo ASC
;


/*
	Como los residentes pueden tener anotaciones con puntuación negativa, se crea una vista que rapidamente permita 
    traer la info de los residentes y sus respectivos puntajes. Para facilidad, esta vista depende de la anterior creada
*/
CREATE VIEW vpuntaje_anotaciones AS	
	SELECT vbd.nombre_completo, vbd.resident_id, vbd.apto_code, IFNULL(SUM(anot.gravedad), 'N/A') AS suma_anots
	FROM vbase_datos_lookat as vbd
	LEFT JOIN anotaciones as anot ON vbd.resident_id = anot.resident_id
	GROUP BY vbd.resident_id
	ORDER BY vbd.nombre_completo ASC
;


/*	
	De acuerdo con el número de contratos activos en el periodo actual, se calcula en número de acomodaciones restantes de cada tipo.
    También se muestra la fecha más próxima en la que un contrato para tal o tal acomodación acaba.
*/
CREATE VIEW vacomodaciones_restantes AS
	WITH acomoda_actual AS (
		SELECT acomoda_id, MIN(fecha_end) AS prox_libre
		FROM contratos
        #Esta fecha simula ser final de semestre 2022-2, para que al revisar el proyecto no sea una vista vacía
		WHERE fecha_end > '2022-06-25'
		GROUP BY resident_id)
	SELECT acom.acomoda_id, acom.totales,  acom.totales-COUNT(contr.acomoda_id) AS restantes, IFNULL(contr.prox_libre, 'N/A') AS fecha_prox_liberacion
	FROM acomodacion as acom
	LEFT JOIN acomoda_actual as contr ON acom.acomoda_id = contr.acomoda_id
	GROUP BY acom.acomoda_id
;


/*
	Promedio de la puntuación de encuestas de satisfacción dadas al final de semestre
    Tiene en cuenta que las puntuaciones posibles están en el rango [1,10]
*/
CREATE VIEW vprom_puntuacion AS
	SELECT 
			IFNULL(AVG(satis_mentores),0)  AS satis_mentores_prom, 
			IFNULL(AVG(satis_limpieza) ,0) AS satis_limpieza_prom, 
			IFNULL(AVG(satis_servicios) ,0) AS satis_servicios_prom, 
			IFNULL(AVG(satis_apto) ,0) AS satis_apto_prom, 
			IFNULL(AVG(satis_instalacion) ,0) AS satis_instalacion_prom, 
			IFNULL(AVG(satis_eventos) ,0) AS satis_eventos_prom, 
			IFNULL(AVG(satis_gestion) ,0) AS satis_gestion_prom
	FROM encuesta
	WHERE satis_mentores>0 AND satis_gestion>0
;


/*
	Crea una vista que cuenta cuantos leads vinieron de cada proveniencia, además de mostrar el número total
*/
CREATE VIEW vorigen_leads AS 
	SELECT 
		SUM(instagram) AS leads_instagram,
		SUM(facebook) AS leads_facebook,
		SUM(whatsapp) AS leads_whatsapp,
		SUM(anotados_eventos) AS leads_anotados_eventos,
		SUM(google_ad) AS leads_google_ad,
		SUM(pagina_web) AS leads_pagina_web,
		COUNT(instagram) AS total_leads
	FROM leads
;
	

/*
	Una última vista que simula el número de contratos vigentes aún para el siguiente semestre. Clasificados de acuerdo
    con nivel de educación y duración del contrato.
*/
CREATE VIEW vcontratos_vigentes_nivelduracion AS
	SELECT nivel, duracion, COUNT(*) AS numero_contratos
	FROM contratos
    #Esta fecha simula ser final de semestre 2022-2, para que al revisar el proyecto no sea una vista vacía
	WHERE fecha_end > '2022-06-25'
	GROUP BY nivel, duracion
	ORDER BY nivel DESC, duracion ASC
;



-- -- -- -- -- -- -- -- -- -- -CREACIÓN DE FUNCIONES- -- -- -- -- -- -- -- -- -- --
/*
	De acuerdo con el número de personas que deseen ingresar a la ciudadela, la función retorna el número de 
    apartamentos totales entre todas las acomodaciones para ese número de personas o un número mayor.
    Asume que el nombre de columna será uno válido.
*/
DELIMITER $
CREATE FUNCTION `fnum_aptos_x_gente`  (numPersonas INT)
RETURNS INT
DETERMINISTIC

BEGIN
	DECLARE numAptos INT;
    SET numAptos = (SELECT SUM(acom.totales)-COUNT(contr.acomoda_id) AS restantes 
					FROM acomodacion as acom
					LEFT JOIN contratos as contr ON acom.acomoda_id = contr.acomoda_id
					WHERE num_cuartos>= numPersonas);
    RETURN numAptos;
END
$
DELIMITER ;


/*
	Retorna el número de residentes con un puntaje de gravedad mayor o igual al ingresado por parámetro
*/
DELIMITER $
CREATE FUNCTION `fnum_gente_grave`  (puntajeGrav INT)
RETURNS INT
DETERMINISTIC

BEGIN
	DECLARE numPersona INT;
    SET numPersona = (SELECT COUNT(*) 
					  FROM (
						SELECT IFNULL(SUM(anot.gravedad), 0) AS suma_anots
						FROM vbase_datos_lookat as vbd
						LEFT JOIN anotaciones as anot ON vbd.resident_id = anot.resident_id
						GROUP BY vbd.resident_id) AS t
					  WHERE suma_anots>=puntajeGrav);
    RETURN numPersona;
END
$
DELIMITER ;



-- -- -- -- -- -- -- -- -- -- -CREACIÓN DE PROCEDIMIENTOS ALMACENADOS- -- -- -- -- -- -- -- -- -- --
/*
	El primer SP recibe un parámetro de acuerdo con el cual ordenar una tabla
    y un segundo parámetro que indique si será ascendiente o descendiente. 
    Asume que el nombre de columna ingresado será válido.
*/
DELIMITER $
CREATE PROCEDURE `sp_ordenar_residentes` (IN columnName VARCHAR(50), IN determOrder VARCHAR(10))
BEGIN
	-- Si los parámetros son diferentes a nulo, genere error y retorne eso mismo
	IF columnName<>'' AND (determOrder IN ('ASC','DESC')) THEN
		SET @params = 1;
	ELSE
		SET @params = 0;
        SET @mensajeError = "SELECT \'Revise los parámetros ingresados' AS Error";
        PREPARE querySQL FROM @mensajeError;
        EXECUTE querySQL;
        DEALLOCATE PREPARE querySQL;
	END IF;
    
    -- Consulta armada, asume que 
    IF @params = 1 THEN
		SET @mensajeQuery = CONCAT('SELECT * FROM ciudadela_universitaria.residentes ORDER BY ',columnName,' ',determOrder);
        PREPARE querySQL FROM @mensajeQuery;
        EXECUTE querySQL;
        DEALLOCATE PREPARE querySQL;
	END IF;
END $
DELIMITER ;

/*
	Se el segundo SP pueda ingresar datos en una tabla
*/
DELIMITER $
CREATE PROCEDURE `sp_insertar_anotacion` (IN resident_id INT, IN gravedad INT, IN descripcion VARCHAR(250), IN mentor_id INT)
BEGIN
	SET @mentor_id_max = (SELECT MAX(mentor_id) FROM mentores);
	IF resident_id<>'' AND (gravedad BETWEEN 0 AND 10) AND descripcion<>'' AND (mentor_id BETWEEN 1 AND @mentor_id_max) THEN
		SET @mensajeQuery = CONCAT('INSERT INTO ciudadela_universitaria.anotaciones(resident_id, gravedad, descripcion, mentor_id, fecha) VALUES(',resident_id,', ',gravedad,',"',descripcion,'",',mentor_id,', CURRENT_TIMESTAMP)');
        PREPARE querySQL FROM @mensajeQuery;
        EXECUTE querySQL;
        DEALLOCATE PREPARE querySQL;
    ELSE
		SET @mensajeError = "SELECT \'Revise los parámetros ingresados' AS Error";
        PREPARE querySQL FROM @mensajeError;
        EXECUTE querySQL;
        DEALLOCATE PREPARE querySQL;
    END IF;
END $
DELIMITER ;



-- -- -- -- -- -- -- -- -- -- -CREACIÓN DE PROCEDIMIENTOS TRIGGERS- -- -- -- -- -- -- -- -- -- --
/*
    Para cada una de las dos tablas de auditoría se generará un triger before y uno after. La primera tabla log se hará en base
    a la tabla de contratos, siendo esta de las tablas más importantes de la base, para empezar a manejar
    registros por el lado económico.
    -------------------------------------------------------------------------------------------------------- 
*/

-- Este trigger con before lo que hace es verificar que la fecha de inicio del contrato o de fin de este no sean 
-- en temporalidades 2 años menores o mayores a las actuales (esto con objetivo de que no se agregue un cero de más
-- o algo similar, se elige dos años porque es el límite para hacer reservas por adelantado y se permite de hace
-- dos años para que no haya problema añadiendo contratos del año pasado o algún caso similar.
DELIMITER $$
CREATE TRIGGER `trigger_verifica_fecha_contrato`
BEFORE INSERT ON contratos
FOR EACH ROW 
BEGIN 
	DECLARE errorMessage VARCHAR(100);
	SET errorMessage= 'Los contratos no pueden tener más o menos de dos años de temporalidad';
    IF (NEW.fecha_inicio >= DATE_ADD(CURRENT_TIMESTAMP,INTERVAL 2 YEAR)) OR (NEW.fecha_inicio <= DATE_ADD(CURRENT_TIMESTAMP,INTERVAL -2 YEAR))
    OR (NEW.fecha_end >= DATE_ADD(CURRENT_TIMESTAMP,INTERVAL 2 YEAR)) OR (NEW.fecha_end <= DATE_ADD(CURRENT_TIMESTAMP,INTERVAL -2 YEAR)) THEN
		SIGNAL SQLSTATE '45000' -- Código generado con inspiración de mysqltutorial.org
         SET MESSAGE_TEXT = errorMessage;
    END IF;
END $$
DELIMITER ;

-- Este trigger con after creará un log con el usuario que realizó la operación, la fecha de realización, y la hora
-- en la que datos fueron añadidos a la tabla de contratos. Todo conectado con el id de los contratos insertados. 
CREATE TRIGGER `trigger_log_contrato_realizado`
AFTER INSERT ON contratos
FOR EACH ROW 
INSERT INTO log_contratos (contract_id, usuario, fecha_hora) 
VALUES (NEW.contract_id, USER(), CURRENT_TIMESTAMP());



/*
    La segunda tabla log se hará en base a la tabla de residentes, siendo esta la tabla con información 
    que puede ser vital en algún momento de la operación.
    -------------------------------------------------------------------------------------------------------- 
*/

-- Este trigger con before lo que hace es verificar que el número y correo ingresados sean válidos
DELIMITER $$
CREATE TRIGGER `trigger_verifica_contacto`
BEFORE INSERT ON residentes
FOR EACH ROW 
BEGIN 
	DECLARE errorMessage VARCHAR(100);
    
    IF (NEW.correo NOT REGEXP '.*@[a-zA-Z0-9]*\\.[a-zA-Z]') THEN
		SET errorMessage= 'Dato de correo ingresado erroneo';
		SIGNAL SQLSTATE '45000'
         SET MESSAGE_TEXT = errorMessage;
	ElSEIF (LENGTH(NEW.numero) <> 10) THEN -- Asume números celulares colombianos de 10 dígitos
		SET errorMessage= 'Dato de número ingresado erroneo';
		SIGNAL SQLSTATE '45000'
         SET MESSAGE_TEXT = errorMessage;
	END IF;    
END $$
DELIMITER ;

-- Este trigger con after creará un log con el usuario que realizó la operación, la fecha de realización, y la hora
-- en la que datos fueron añadidos a la tabla de contratos. Todo conectado con el id de los residentes registrados. 
CREATE TRIGGER `trigger_log_residente_registrado`
AFTER INSERT ON residentes
FOR EACH ROW 
INSERT INTO log_residente (resident_id, usuario, fecha_hora) 
VALUES (NEW.resident_id, USER(), CURRENT_TIMESTAMP());



-- -- -- -- -- -- -- -- -- -- -- -- -INSERCIÓN DE DATOS- -- -- -- -- -- -- -- -- -- -- -- --
#Se llenarán las bases de datos con datos falsos, generados solamente para el ejercicio de llenar la base

#Primero creamos nuestros residentes
INSERT INTO residentes (resident_id, fecha_registro, fecha_nacimiento, nombres, apellidos, numero, correo, universidad, programa, locacion, sexo)
VALUES 
	(1034363421, DEFAULT,'2002-07-12','Danna Isabella','Arcila','3437954172','di.arcilaa@unibogota.edu.co','Universidad de Bogotá','Ciencia Política','Rionegro, Antioquia','M'),
    (1020172942, DEFAULT,'2003-04-24','Mariana','Cardenas','3155684752','m.cardenasm@urosario.edu.co','Universidad del Rosario','Economía','Bogotá, Bogotá D.C.','M'),
    (1092934512, DEFAULT,'2001-09-20','Juan Sebastian','Serrano','3238956872','js.serrano12@unal.edu.co','Universidad Nacional','Ingeniería Civil','Armenia, Quindío','H'),
    (1097962340, DEFAULT,'2003-06-25','Isabela','Medina','3637859847','isa.medicina@gmail.com','Universidad de los Andes','Medicina','Medellín, Antioquia','M'),
    (1054275421, DEFAULT,'2002-07-12','Camilo Andres','Bohorquez','3635897845','bohorquesito@gmail.com','Universidad de Bogotá','Derecho','Neiva, Huila','H'),
    (1023457234, DEFAULT,'2001-05-04','Martin Ricardo','Bohorquez','3136987458','mr.bohorquezg@unibogota.edu.co','Universidad de Bogotá','Medicina','Neiva, Huila','H'),
    (1034756263, DEFAULT,'2004-08-12','Santiago','Trujillo','3524789547','santuska@hotmail.com','Universidad del Rosario','Ingeniería Biomédica','Duitama, Boyacá','H'),
    (1034592340, DEFAULT,'2002-12-11','Ana Maria','Blanco','3435768312','am.blancob@uniandes.edu.co','Universidad de los Andes','Diseño','Chía, Cundinamarca','M'),
    (1023482345, DEFAULT,'2002-01-23','Maria Angelica','Lizarazo','3432932312','ma.lizarazo@uexternado.edu.co','Universidad Externado','Derecho','Pereira, Risaralda','M'),
    (1023457632, DEFAULT,'1999-01-08','Maria Camila','Rodriguez','3125832143','mc.rodriguezg@uniandes.edu.co','Universidad de los Andes','Ciencia Política','Neiva, Huila','M'),
    (1092384723, DEFAULT,'2003-10-26','Luis','Arias','3233948574','l.ariasb@unibogota.edu.co','Universidad de Bogotá','Matemáticas','Circasia, Quindío','H'),
    (1023948321, DEFAULT,'2004-02-26','Laura Camila','Garcia','3847364235','lc.garcial@urosario.edu.co','Universidad del Rosario','Economía','Tunja, Boyacá','M'),
    (1023847526, DEFAULT,'2001-03-22','Laura Andrea','Palacio','3192387426','la.palacioe@ujaveriana.edu.co','Universidad Javeriana','Comunicación Social','Rionegro, Antioquia','M'),
    (1093832734, DEFAULT,'2003-07-25','Felipe','Buendia','3239387482','f.buendia2@uniandes.edu.co','Universidad de los Andes','Ingeniería Mecánica','Bucaramanga, Santander','H'),
    (1092345421, DEFAULT,'2003-08-05','Juan José','Gomez','3896478958','jj.gomezg@unibogota.edu.co','Universidad de Bogotá','Biología','Bogotá, Bogotá D.C.','H')
;

#Se llena la tabla de asistentes de residencia / mentores del semestre
INSERT INTO mentores (mentor_id, nombres, apellidos, numero)
VALUES
	(1, 'Paula', 'Perez', '3127953245'),
    (2, 'Kevin', 'Bejarano', '3958374632'),
    (3, 'Nasly', 'Ortiz', '3084957426'),
    (4, 'Carolina', 'Otero', '3167954323')
;

INSERT INTO mesa (mesa_descripcion)
VALUES
	('Mesa cuadrada 2 puestos'),
    ('Mesa redonda 4 puestos'),
    ('2 Mesas cuadradas 2 puestos')
;

#Se llena la base actual (Se repiten datos de mentores en vez de normalizar para 
INSERT INTO base_actual (resident_id, apto_code, llegada_fecha, mentor_id, uso_imagen)
VALUES
	(1034363421, '22103A', DEFAULT, 1, 1),
    (1020172942, '20404B', DEFAULT, 2, 0),
    (1092934512, '12210A', DEFAULT, 3, 1),
    (1097962340, '22103B', DEFAULT, 1, 1),
    (1054275421, '30406A', DEFAULT, 4, 1),
    (1023457234, '30406B', DEFAULT, 4, 1),
    (1034756263, '11907A', DEFAULT, 3, 0),
    (1034592340, '22306B', DEFAULT, 1, 1),
    (1023482345, '12209A', DEFAULT, 3, 1),
    (1023457632, '30702B', DEFAULT, 4, 1),
    (1092384723, '20803A', DEFAULT, 2, 0),
    (1023948321, '20905A', DEFAULT, 2, 1),
    (1023847526, '22209B', DEFAULT, 1, 1),
    (1093832734, '22104A', DEFAULT, 1, 1),
    (1092345421, '11905A', DEFAULT, 3, 1)
;

#Se llena la base de anotaciones
INSERT INTO anotaciones (resident_id, gravedad, descripcion, mentor_id, fecha)
VALUES
	(1054275421, 0, 'Vive con su hermano menor, pidieron no quedar de nuevo en mismo piso que Juan José Gomez 1092345421', 4,DEFAULT),
    (1092384723, 4, 'Queja de ruido en horas de la madrugada 3:00am. No hubo más quejas tras avisarle', 2,DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -14 DAY)),
    (1092384723, 4, 'Queja de ruido en horas de silencio 1:20am No hubo más quejas tras avisarle', 2, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -6 DAY)),
    (1034592340, 0, 'Presentó gripa, se tuvo que contactar a medico externo. Prueba covid pendiente', 1,DATE_ADD(CURRENT_TIMESTAMP,INTERVAL -3 DAY)),
    (1023847526, 7, 'Se el encontró tomando en una zona común, acción prohibida en la vivienda', 3,DATE_ADD(CURRENT_TIMESTAMP,INTERVAL -10 DAY)),
    (1092934512, 5, 'Rayón en pared de la cocina comunal, aceptó culpa', 2,DATE_ADD(CURRENT_TIMESTAMP,INTERVAL -2 DAY)),
    (1023457234, 2, 'Llegó borracho a la ciudadela, requirió asistencia de los mentores para llegar a habitación', 3,DATE_ADD(CURRENT_TIMESTAMP,INTERVAL -6 DAY) ),
    (1097962340, 3, 'Queja por acoso verbal hacia otra residente Laura Andrea Palacio (1023847526)', 1,DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -4 DAY)),
    (1034756263, 5, 'Perdida de protector de colchón en su habitación, dicen nunca haberlo tenido', 3, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -1 DAY)),
    (1092384723, 8, 'Queja de ruido en horas de silencio 4:20am. Se tuvo que advertir dos veces', 2, CURRENT_TIMESTAMP),
    (1034363421, 0, 'Alergica a las nueces', 1, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL -15 DAY))
;

#Se llena la base de acomodaciones
INSERT INTO acomodacion (acomoda_id, num_cuartos, num_banios, sofa, mesa_id, descripcion, totales)
VALUES 
	('1A', 1, 1, 1, 1, 'Individual grande, 2 closets.', 10),
    ('1B', 1, 1, 0, 1, 'Individual reducida.', 16),
    ('2A', 2, 2, 1, 1, 'Doble con sofa y dos baños', 12),
    ('2AI', 2, 1, 1, 1, 'Doble con sofa y un baño', 12),
    ('2B', 2, 2, 0, 1, 'Doble sin sofa, esquinera de 4 reacomodada. Dos baños', 16),
    ('2C', 2, 1, 0, 1, 'Doble genérica.', 40),
    ('2D', 2, 1, 0, 1, 'Doble reducida.', 20),
    ('3A', 3, 2, 1, 1, 'Triple con sofa.', 8),
    ('3B', 3, 2, 0, 1, 'Triple sin sofa', 8),
    ('3BI', 3, 2, 1, 1, 'Triple con cuarto compartido entre dos', 8),
    ('4A', 4, 2, 0, 2,'Cuadruple genérica grande.', 40),
    ('4AI', 4, 2, 0, 2, 'Cuadruple genérica reducida', 40),
    ('4B', 4, 2, 0, 3, 'Cuadruple larga', 32)
;

#Se llena la base de encuestas
INSERT INTO encuesta (satis_mentores, satis_limpieza, satis_servicios, satis_apto, satis_instalacion, satis_eventos, satis_gestion, anadicion)
VALUES 
	(10,10,10,10,10,10,10,''),
    (10,9,9,10,10,7,10,'El internet se caia a veces y los eventos podrían ser un poco más variados'),
    (5,10,10,10,10,10,5,'Tuve un problema con otro residente y en todo el semestre los mentores no hicieron nada'),
    (8,9,9,9,9,9,1,'Falta de organización para resolver problemas presentados durante el semestre'),
    #Si el semestre no ha terminado, la encuesta esta creada pero vacía
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,''),
    (0,0,0,0,0,0,0,'')
;

INSERT INTO leads (lead_id, red_social, telefono, correo, instagram, facebook, whatsapp, anotados_eventos, google_ad, pagina_web, 
alterno_contacto, first_approach, interes, contract_id)
VALUES
	(1, '@marianacm24','','',1,0,0,0,0,0,'Número de su madre: 3637895478',1,1, 1),
    (2, '','3238956872','js.serrano12@unal.edu.co',0,0,0,0,0,1,'',1,1, 2),
	(3, '','','',0,0,1,1,0,0,'Número de su padre: 3635789848',1,1, 3),
    (4, '', '3896478958','jj.gomezg@unibogota.edu.co',0,0,0,1,0,0,'Número de su madre: 3039485734',1,1, 4),
    (5, 'dannaarcilaa.3','','',1,0,0,0,0,0,'',1,1, 5),
    (6, 'isa_medicina12','3637859847','',1,0,1,0,0,0,'Número de su padre: 3259844721',1,1, 8),
    (7, '','','',0,0,1,0,0,0,'Número de su padre: 3635789848',1,1, 10),
    (8, '', '3524789547', 'santuska@hotmail.com',0,0,1,0,1,0,'',1,1, 11),
    (9, '','3435768312','am.blancob@uniandes.edu.co',0,0,1,0,0,1,'',1,1,12),
    (10, '@angellizard','','ma.lizarazo@uexternado.edu.co',1,0,0,0,1,0,'Número de su madre: 3928433721',1,1,13),
    (11,'','3125832143','mc.rodriguezg@uniandes.edu.co',0,0,0,0,0,1,'',1,1,14),
    (12,'','3233948574','l.ariasb@unibogota.edu.co',0,0,0,0,0,1,'',1,1,15),
	(13,'','3847364235','',0,0,1,0,1,0,'Número de su madre: 3539373245',1,1,16),
	(14, '', '3192387426','la.palacioe@ujaveriana.edu.co', 0,0,0,0,0,1,'',1,1,17),
	(15, '', '3239387482', '', 0,0,1,0,0,0,'',1,1,18)
;

#Se llena la base de historico de contratos
INSERT INTO contratos (resident_id, encuesta_id, acomoda_id, lead_id, duracion, nivel, fecha_inicio, fecha_end, valor, semestre, enviado, firmado
, contado, manual, eps, numero_responsable, responsable, anotaciones)
VALUES
    #4 registros simulando contratos de semestres previos
    (1020172942, 1, '4A', 1,'Semestre', 'Pregrado', '2022-01-23','2022-06-23',5500000, 4,1,1,1,1,'Nueva EPS','3637895478','Marta Murillo','Ninguna'),
    (1092934512, 2, '2C', 2, 'Semestre', 'Maestria', '2022-01-25','2022-01-06',6500000, 2,1,1,1,1,'Sura','3238956872','Juan Sebastian Serrano','Ninguna'),
    (1054275421, 3, '2A', 3, 'Semestre', 'Pregrado', '2022-01-20','2022-06-20', 6750000, 3, 1,1,1,1,'Sanitas', '3635789848', 'Emilio Bohorquez', 'Ninguna'),
    (1092345421, 4, '2A', 4, 'Semestre', 'Pregrado', '2022-01-22','2022-06-22', 6750000, 3,1,1,1,1,'Sanitas', '3039485734','Sandra Giraldo', 'Ninguna'),
    
    #Contratos de este semestre, todos los residentes volvieron
	(1034363421, 5, '4AI', 5,'Semestre', 'Pregrado', '2022-07-25','2022-12-25',5500000, 5,1,1,1,1,'Sura','3254789586','Carlos Arcila','Ninguna'),
    (1020172942, 6, '4A', 1,'Semestre', 'Pregrado', '2022-07-22','2022-12-22',5500000, 5,1,1,1,1,'Nueva EPS','3637895478','Marta Murillo','Ninguna'),
    (1092934512, 7, '2C', 2, 'Año', 'Maestria', '2022-08-06','2023-08-06',14300000, 3,1,1,0,1,'Sura','3238956872','Juan Sebastian Serrano','Ninguna'),
    (1097962340, 8, '4AI', 6, 'Semestre', 'Pregrado', '2022-08-08', '2023-01-08', 5500000, 2,1,1,1,1,'Colsanitas','3259844721','Camilo Medina','Ninguna'),
    (1054275421, 9, '2A', 3, 'Semestre', 'Pregrado', '2022-07-25','2022-12-25', 6750000, 4, 1,1,1,1,'Sanitas', '3635789848', 'Emilio Bohorquez', 'Quedar en el mismo aptartamento que su hermano'),
    (1023457234, 10, '2A', 7, 'Semestre', 'Pregrado', '2022-07-25','2022-12-25', 6750000, 1, 1,1,1,1,'Sanitas', '3635789848', 'Emilio Bohorquez', 'Quedar en el mismo aptartamento que su hermano'),
    (1034756263, 11, '1A', 8, 'Semestre', 'Pregrado', '2022-07-22','2022-12-22', 7500000, 2,1,1,0,1,'Nueva EPS','3159283643','Emilia Arias','Ninguna'),
    (1034592340, 12, '2D', 9, 'Semestre', 'Maestria', '2022-08-08', '2023-01-08', 6250000, 1,1,1,1,1,'Sura','3435768312','Ana Maria Blanco','Ninguna'),
    (1023482345, 13, '2A', 10, 'Año', 'Maestria', '2022-07-28','2023-07-28', 14850000, 2,1,1,1,1,'Nueva EPS','3928433721','Susana Lizarazo','Ninguna'),
    (1023457632, 14, '3A', 11, 'Año', 'Pregrado', '2022-08-08', '2023-01-08', 6350000, 1,1,1,0,1,'Sura','3459387216','Dalia García','Ninguna'),
    (1092384723, 15, '4AI', 12, 'Año', 'Pregrado', '2022-07-25','2022-12-25', 12100000, 3, 1,1,0,1, 'Colsanitas', '3467854789','Nora Botero','Ninguna'),
    (1023948321, 16, '4B', 13, 'Semestre', 'Maestria', '2022-07-22','2022-12-22', 5500000, 1,1,1,1,1,'Nueva EPS', '3539373245','Marina Londoño','Ninguna'),
    (1023847526, 17, '2B', 14, 'Año', 'Pregrado', '2022-08-10', '2023-01-10', 6300000, 3,1,1,0,1,'Sura','3948377212','Andrés Palacio','Ninguna'),
    (1093832734, 18, '1A', 15, 'Mes', 'Maestria', '2022-08-08', '2022-09-08', 1500000, 2,1,1,1,1,'Nueva EPS','3239387482','Felipe Buendia','Ninguna'),
    (1092345421, 19, '2A', 4, 'Año', 'Pregrado', '2022-07-25', '2023-07-25', 14850000, 4,1,1,1,1,'Sanitas', '3039485734','Sandra Giraldo', 'Ninguna')
;



-- -- -- -- -- -- -- -- -- -- -- -- -CREACIÓN DE USUARIOS- -- -- -- -- -- -- -- -- -- -- -- --
/*
	Se crearon dos usuarios. 
	El primero tendrá permisos de lectura sobre todas las tablas.
   El segundo tendrá permisos de lectura, inserción, y modificación de datos
*/
-- Se crea el primer usuario
CREATE USER `user1`@`localhost` IDENTIFIED WITH mysql_native_password BY 'contrasenia1';

-- Se le da permiso de solo lectura a este primer usuario en las tablas del proyecto
GRANT SELECT ON ciudadela_universitaria.* TO `user1`@`localhost`;

-- Se crea el segundo usuario 
CREATE USER `user2`@`localhost` IDENTIFIED BY 'contrasenia2';

-- Se le da permiso de lectura, inserción, y modificación de datos al segundo usuario
GRANT SELECT, UPDATE, INSERT ON ciudadela_universitaria.* TO `user2`@`localhost`;