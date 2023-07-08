--Aceasta cerere obtine numele salii si numarul de sponsori ai fiecarei sali, pentru fiecare sala ce are mai mult de un sponsor si numarul de sponsori ai salii este mai mic decat numarul de membrii ai tuturor salilor
--care au o varsta mai mare decât media varstelor tuturor membrilor.
-- • subcereri nesincronizate în clauza FROM
-- • grupari de date cu subcereri nesincronizate in care intervin cel putin 3 tabele, functii grup, filtrare la nivel de grupuri (in cadrul aceleiasi cereri)
SELECT s.nume_sala AS NUME_SALA, COUNT(s.id_sala) AS NUMAR_SPONSORI
FROM sala s, contract_sponsor cs 
WHERE s.id_sala = cs.id_sala
GROUP BY s.nume_sala
HAVING COUNT(s.id_sala) > 1 AND COUNT(s.id_sala) < (
    SELECT COUNT(*)
    FROM (
        SELECT *
        FROM MEMBRU
        WHERE TO_NUMBER(TO_CHAR(data_nasterii, 'YYYY')) > (
            SELECT AVG(TO_NUMBER(TO_CHAR(data_nasterii, 'YYYY')))
            FROM MEMBRU
        )
    )
);

--Aceasta cerere obtine informatii despre toate programele cu id-ul mai mare decat 1 care sunt folosite de cel putin o clasa cu id-ul mai mare decat 1.
-- • subcereri sincronizate în care intervin cel putin 3 tabele
SELECT 
  (SELECT c.data 
   FROM clasa c
   WHERE f.id_clasa = c.id_clasa) AS DATA_CLASA,
  (SELECT p.nume 
   FROM programe p
   WHERE f.id_antrenament = p.id_antrenament) AS NUME_ANTRENAMENT,
  f.id_clasa,
  f.id_antrenament
FROM FOLOSESTE f
WHERE f.id_clasa > 1 AND f.id_antrenament > 1;

--Aceasta cerere afiseaza un raport referitor la numele salii, numele antrenorilor, specialitatea lor (daca exista, in caz ca nu exista va aparea 'Fara specializare') si genul vestiarelor din sala respectiva 
--('Masculin' sau 'Feminin').
-- • ordonari si utilizarea functiilor NVL si DECODE (in cadrul aceleiasi cereri)
SELECT DISTINCT s.nume_sala, a.nume_angajat AS nume_antrenor, NVL(a1.specializare, 'Fara specializare') AS specializare_antrenor,
       DECODE(v.tip_vestiar, 'M', 'Masculin', 'Feminin') AS gen_vestiar
FROM sala s
JOIN angajat a ON s.id_sala = a.id_sala
LEFT JOIN antrenor a1 ON a1.id_angajat = a.id_angajat
LEFT JOIN vestiar v ON s.id_sala = v.id_sala
ORDER BY s.nume_sala;

--Aceasta cerere obtine numele salilor, numele sponsorilor si numarul de contracte incheiate pentru fiecare sala.
-- • utilizarea a cel putin 1 bloc de cerere (clauza WITH)
WITH contracte_sala AS (
  SELECT s.id_sala, s.nume_sala, sp.nume_sponsor
  FROM sala s
  JOIN contract_sponsor cs ON s.id_sala = cs.id_sala
  JOIN sponsor sp ON cs.id_sponsor = sp.id_sponsor
)
SELECT cs.nume_sala, cs.nume_sponsor, COUNT(*) AS numar_contracte
FROM contracte_sala cs
GROUP BY cs.id_sala, cs.nume_sala, cs.nume_sponsor;

--Aceasta cerere furnizeaza informatii despre sali si sponsori, inclusiv numele salii, numele sponsorului, data contractului si o evaluare a duratei contractului în functie de diferenta in luni fata de data curenta.
-- • utilizarea a cel putin 2 functii pe siruri de caractere, 2 functii pe date calendaristice, a cel putin unei expresii CASE
  SELECT
  LOWER(s.nume_sala) AS "Nume Sala",
  UPPER(sp.nume_sponsor) AS "Nume Sponsor",
  TO_CHAR(cs.data_contract, 'DD-MM-YYYY') AS "Data Contract",
  CASE
    WHEN MONTHS_BETWEEN(SYSDATE, cs.data_contract) >= 6 THEN 'Contractul are o durata mai mare sau egala cu 6 luni'
    ELSE 'Contractul are o durata mai mica de 6 luni'
  END AS "Durata Contract"
FROM
  CONTRACT_SPONSOR cs
  INNER JOIN SALA s ON cs.id_sala = s.id_sala
  INNER JOIN SPONSOR sp ON cs.id_sponsor = sp.id_sponsor;



--Actualizarea capacitatii unui vestiar cu +10, in functie de ID-ul vestiarului ('100' este un placeholder pentru id-ul dorit), daca media capacitatilor tuturor vestiarelor din sala respectiva este mai mica de 50.
UPDATE VESTIAR
SET capacitate = capacitate + 10
WHERE id_vestiar = 100
  AND id_sala = (
    SELECT id_sala
    FROM VESTIAR
    WHERE id_vestiar = 100
  )
  AND (
    SELECT AVG(capacitate)
    FROM VESTIAR
    WHERE id_sala = (
      SELECT id_sala
      FROM VESTIAR
      WHERE id_vestiar = 100
    )
  ) < 50;

--Stergerea tuturor sponsorilor care au in numele lor un anumit subsir ('%DJADOHAODIA%' este un placeholder) si care au cel putin 2 contracte active.
DELETE FROM SPONSOR s
WHERE s.nume_sponsor LIKE '%DJADOHAODIA%' and (SELECT COUNT(id_sala)
                                                FROM CONTRACT_SPONSOR
                                                WHERE id_sponsor=s.id_sponsor) > 1;
    
--Actualizarea tuturor programelor cu ID-ul mai mare decat 100 si care sunt folosite de cel putin 4 clase.
UPDATE PROGRAME p
SET timp_start = timp_start + INTERVAL '1' HOUR,
    timp_final = timp_final + INTERVAL '1' HOUR
WHERE p.id_antrenament > 100 and (SELECT COUNT(id_antrenament)
                                    FROM FOLOSESTE
                                    WHERE id_antrenament=p.id_antrenament) > 3;



--Cererea cu OUTER JOIN pe minimum 4 tabele, utilizând FULL OUTER JOIN:
--Aceasta cerere va afisa informatii despre contractele de sponsorizare, sali, echipamente si locatiile asociate acestora. Vom utiliza tabelele "CONTRACT_SPONSOR", "SALA", "ECHIPAMENT" si "LOCATIE".
SELECT *
FROM CONTRACT_SPONSOR
FULL OUTER JOIN SALA ON CONTRACT_SPONSOR.id_sala = SALA.id_sala
FULL OUTER JOIN SPONSOR ON CONTRACT_SPONSOR.id_sponsor =SPONSOR.id_sponsor
FULL OUTER JOIN LOCATIE ON SALA.id_sala = LOCATIE.id_sala
FULL OUTER JOIN ECHIPAMENT ON SALA.id_sala=ECHIPAMENT.id_sala;

--Cererea cu DIVISION 
--Aceasta cerere selecteaza id-ul tuturor ingrijitorilor care ingrijesc vestiare cu capacitatea 120
SELECT DISTINCT A.id_ingrijitor AS "Ingrijitori"
FROM INGRIJESTE A
WHERE NOT EXISTS (
  SELECT id_vestiar
  FROM VESTIAR P
  WHERE capacitate = 120
  AND NOT EXISTS (
    SELECT 1
    FROM INGRIJESTE B
    WHERE P.id_vestiar = B.id_vestiar
    AND B.id_ingrijitor = A.id_ingrijitor
  )
);

--Cererea cu analiza top-n
--Aceasta cerere selecteaza primele 3 cele mai scumpe abonamente din tot lantul de sali.
SELECT *
FROM ABONAMENT
WHERE pret IN (SELECT pret
FROM (
  SELECT DISTINCT pret
  FROM ABONAMENT
  ORDER BY pret DESC
) 
WHERE ROWNUM <= 3); 



--Cererea neoptimizata
--Aceasta cerere selecteaza numele salilor si data contractelor pentru salile cu ID-ul mai mic decat 3 si contin in nume 'Gym'
SELECT s.nume_sala, c.data_contract
FROM CONTRACT_SPONSOR c
JOIN SALA s ON s.id_sala=c.id_sala
WHERE s.id_sala IN (
    SELECT s1.id_sala
    FROM SALA s1
    WHERE s.id_sala=s1.id_sala AND s1.id_sala <=3 AND s.nume_sala IN (
        SELECT s2.nume_sala
        FROM SALA s2
        WHERE s.id_sala=s2.id_sala AND s2.nume_sala LIKE '%Gym%'
        )
    )

--Cererea optimizata
--Aceasta cerere selecteaza numele salilor si data contractelor pentru salile cu ID-ul mai mic decat 3 si contin in nume 'Gym'
SELECT s.nume_sala, c.data_contract
FROM (SELECT id_sala, nume_sala
      FROM SALA
      WHERE id_sala <=3 AND nume_sala LIKE '%Gym%')s
JOIN (SELECT id_sala, data_contract
      FROM CONTRACT_SPONSOR) c ON c.id_sala=s.id_sala