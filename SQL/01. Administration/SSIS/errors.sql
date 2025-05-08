
-- An error occurred during Service Master Key decryption" when trying to create SSIS catalog
-- https://stackoverflow.com/questions/26637592/an-error-occurred-during-service-master-key-decryption-when-trying-to-create-s
ALTER SERVICE MASTER KEY FORCE REGENERATE;
