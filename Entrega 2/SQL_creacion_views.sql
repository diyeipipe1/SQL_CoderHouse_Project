USE ciudadela_universitaria;

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





