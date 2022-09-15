USE ciudadela_universitaria;

/*
	Estos triggers se crean siguiendo las instrucciones de la asignación de la semana.
    Se pide que se elijan dos tablas a partir de las cuales se crearan tablas de bitacora.
    Para cada tabla se generará un triger before y uno after. La primera tabla log se hará en base
    a la tabla de contratos, siendo esta de las tablas más importantes de la base, para empezar a manejar
    registros por el lado económico.
    -------------------------------------------------------------------------------------------------------- 
*/
CREATE TABLE IF NOT EXISTS log_contratos(
	contract_id INT NOT NULL UNIQUE,
    usuario VARCHAR(100) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (contract_id)
		REFERENCES contratos(contract_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

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

-- Pruebas (Before y del after)
/*
-- -- -- -- -- -- -- -- -- -- Before
INSERT INTO encuesta (satis_mentores, satis_limpieza, satis_servicios, satis_apto, satis_instalacion, satis_eventos, satis_gestion, anadicion)
VALUES 
	(10,10,10,10,10,10,10,'')
;
INSERT INTO contratos (resident_id, encuesta_id, acomoda_id, lead_id, duracion, nivel, fecha_inicio, fecha_end, valor, enviado, firmado
, contado, manual, eps, numero_responsable, responsable, anotaciones)
VALUES
    (1054275421, 20, '2A', 3,'Semestre', 'Pregrado', '2022-01-20','2022-06-20', 6750000, 1,1,1,1,'Sanitas', '3635789848', 'Emilio Bohorquez', 'Ninguna')
;

-- -- -- -- -- -- -- -- -- -- After
INSERT INTO encuesta (satis_mentores, satis_limpieza, satis_servicios, satis_apto, satis_instalacion, satis_eventos, satis_gestion, anadicion)
VALUES 
	(10,10,10,10,10,10,10,'')
;
INSERT INTO contratos (resident_id, encuesta_id, acomoda_id, lead_id, duracion, nivel, fecha_inicio, fecha_end, valor, enviado, firmado
, contado, manual, eps, numero_responsable, responsable, anotaciones)
VALUES
    (1054275421, 21, '2A', 3,'Semestre', 'Pregrado', '2040-01-20','2040-06-20', 6750000, 1,1,1,1,'Sanitas', '3635789848', 'Emilio Bohorquez', 'Ninguna')
;
*/



/*
    Se pide que se eligan dos tablas a partir de las cuales se crearan tablas de bitacora.
    Para cada tabla se generará un triger before y uno after. La segunda tabla log se hará en base
    a la tabla de residentes, siendo esta la tabla con información que puede ser vital en algún
    momento de la operación.
    -------------------------------------------------------------------------------------------------------- 
*/
CREATE TABLE IF NOT EXISTS log_residente(
	resident_id INT NOT NULL UNIQUE,
    usuario VARCHAR(100) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (resident_id)
		REFERENCES residentes(resident_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

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

-- Pruebas (Before y del after)
/*
-- -- -- -- -- -- -- -- -- -- Before
INSERT INTO residentes (resident_id, fecha_registro, fecha_nacimiento, nombres, apellidos, numero, correo, universidad, programa, locacion)
VALUES 
(1092341331, DEFAULT,'2003-08-05','Juan José','Gomez','38964783958','jj.gomezg@unibogota.edu.co','Universidad de Bogotá','Biología','Bogotá, Bogotá D.C.')
;

INSERT INTO residentes (resident_id, fecha_registro, fecha_nacimiento, nombres, apellidos, numero, correo, universidad, programa, locacion)
VALUES 
(1092341331, DEFAULT,'2003-08-05','Juan José','Gomez','3896483958','jj.gomezg@unibogotaeduco','Universidad de Bogotá','Biología','Bogotá, Bogotá D.C.')
;

-- -- -- -- -- -- -- -- -- -- After
INSERT INTO residentes (resident_id, fecha_registro, fecha_nacimiento, nombres, apellidos, numero, correo, universidad, programa, locacion)
VALUES 
(1092341231, DEFAULT,'2003-08-05','Juan José','Gomez','3896478958','jj.gomezg@unibogota.edu.co','Universidad de Bogotá','Biología','Bogotá, Bogotá D.C.')
;
*/