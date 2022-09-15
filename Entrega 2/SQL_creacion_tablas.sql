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


