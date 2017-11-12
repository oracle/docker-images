/* 
ORDS_METADATA is the owner of the PL/SQL packages used for implementing many 
Oracle REST Data Services capabilities. ORDS_METADATA is where the metadata 
about Oracle REST Data Services-enabled schemas is stored. 
See See https://docs.oracle.com/cd/E56351_01/doc.30/e87809/installing-REST-data-services.htm#AELIG7180

Our sample user has to execute some PL/SQL code of this schema, therefore it needs
to have privileges on ORDS_METADATA
See https://docs.oracle.com/database/121/DBSEG/dr_ir.htm#DBSEG659
*/
GRANT inherit privileges ON USER pdbadmin TO ORDS_METADATA;
