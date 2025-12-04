SELECT ROWNUM,
       P.col001,
       P.col002,
       P.col003,
       P.col004,
       P.col005,
       P.col006,
       P.col007,
       P.col008,
       P.col009,
       P.col010,
       P.col011,
       P.col012,
       P.col013,
       P.col014,
       P.col015,
       P.col016
FROM APEX_APPLICATION_TEMP_FILES F,
     TABLE(
         APEX_DATA_PARSER.parse(
             p_content         => F.BLOB_CONTENT,
             p_file_name       => F.FILENAME,
             p_add_headers_row => 'Y',
             p_csv_enclosed    => '',
             p_max_rows        => 20
         )
     ) P
WHERE F.NAME = :P7_FILE
  AND P.LINE_NUMBER >= 1; 
