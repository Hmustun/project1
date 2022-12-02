						-- IMPORTING DATA --
                        
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 'ON';
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 'ON';
SHOW GLOBAL VARIABLES LIKE 'local_infile';

CREATE TABLE houses (
	DummyID VARCHAR(255),
    UniqueID VARCHAR(255),
    ParcelID VARCHAR(255),
    LandUse VARCHAR(255),
    PropertyAddress VARCHAR(255),
    SaleDate VARCHAR(255),
    SalePrice VARCHAR(255),
    LegalReference VARCHAR(255),
    SoldAsVacant VARCHAR(255),
    OwnerName VARCHAR(255),
    OwnerAddress VARCHAR(255),
    Acreage VARCHAR(255),
    TaxDistrict VARCHAR(255),
    LandValue VARCHAR(255),
    BuildingValue VARCHAR(255),
    TotalValue VARCHAR(255),
    YearBuilt VARCHAR(255),
    Bedrooms VARCHAR(255),
    FullBath VARCHAR(255),
    HalfBath VARCHAR(255)
);

-- DROP TABLE houses;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\P2\\Nashville Housing Data for Data Cleaning.csv'
INTO TABLE nashville.houses
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

ALTER TABLE houses DROP COLUMN DummyID;

						-- CLEANING DATA IN SQL QUERIES --

SELECT * FROM houses;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Standardise Date Format
UPDATE houses 
SET 
    SaleDate = REPLACE(SaleDate, ',', '');
    
SELECT SaleDate FROM houses;

UPDATE houses 
SET 
    SaleDate = str_to_date(SaleDate, '%M%d%Y');
    
SELECT * FROM houses;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Converting columns to integer values
UPDATE houses 
SET 
    UniqueID = CAST(UniqueID AS UNSIGNED),
    ParcelID = CAST(ParcelID AS UNSIGNED),
    SalePrice = CAST(SalePrice AS UNSIGNED),
    Acreage = CAST(Acreage AS UNSIGNED),
    LandValue = CAST(LandValue AS UNSIGNED),
    BuildingValue = CAST(BuildingValue AS UNSIGNED),
    TotalValue = CAST(TotalValue AS UNSIGNED),
    YearBuilt = CAST(YearBuilt AS UNSIGNED),
    Bedrooms = CAST(Bedrooms AS UNSIGNED),
    FullBath = CAST(FullBath AS UNSIGNED),
    HalfBath = CAST(HalfBath AS UNSIGNED);

SELECT * FROM houses;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data

SELECT * FROM houses WHERE PropertyAddress = "";

SELECT * FROM houses ORDER BY ParcelID;

SELECT 
    a.ParcelID,
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    IF(a.propertyaddress = '',
        b.propertyaddress,
        '') AS PropertyAddressFilled
FROM
    nashville.houses a
        JOIN
    nashville.houses b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID
WHERE
    a.PropertyAddress = '';
   
   
UPDATE nashville.houses a
        JOIN
    nashville.houses b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID 
SET 
    a.PropertyAddress = IF(a.PropertyAddress = '',
        b.PropertyAddress,
        '')
WHERE
    a.PropertyAddress = '';
    
SELECT * FROM houses WHERE PropertyAddress = '';
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress from houses;

SELECT 
    SUBSTR(PropertyAddress,
        1,
        LOCATE(',', PropertyAddress) - 1) AS Address,
    SUBSTR(PropertyAddress,
        LOCATE(',', PropertyAddress) + 1,
        LENGTH(PropertyAddress)) AS City
FROM
    houses;
    
ALTER TABLE houses ADD PropertySplitAddress VARCHAR(255);
UPDATE houses SET PropertySplitAddress = SUBSTR(PropertyAddress ,1, LOCATE(',', PropertyAddress) - 1);

ALTER TABLE houses ADD PropertySplitCity VARCHAR(255);
UPDATE houses SET PropertySplitCity = SUBSTR(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));

SELECT * FROM houses;

SELECT OwnerAddress FROM houses;

SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', 1),
    SUBSTRING_INDEX(SUBSTR(OwnerAddress, LOCATE(',', OwnerAddress,1)+1),',',1),
    SUBSTRING_INDEX(OwnerAddress, ',', -1)
FROM
    houses;
   
ALTER TABLE houses ADD OwnerSplitAddress VARCHAR(255);
UPDATE houses SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE houses ADD OwnerSplitCity VARCHAR(255);
UPDATE houses SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTR(OwnerAddress, LOCATE(',', OwnerAddress,1)+1),',',1);

ALTER TABLE houses ADD OwnerSplitState VARCHAR(255);
UPDATE houses SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT * FROM houses;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT
    (SoldAsVacant), COUNT(SoldAsVacant)
FROM
    houses
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT 
    SoldAsVacant,
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS SoldAsVacant2
FROM
    houses;
    
UPDATE houses 
SET 
    SoldAsVacant = CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

SELECT * FROM (
SELECT 
    *,
    ROW_NUMBER()
OVER (PARTITION BY  ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference) AS row_num
FROM
    houses) AS temp_table WHERE row_num > 1;
    

DELETE FROM houses WHERE UniqueID IN 
(SELECT UniqueID FROM
(SELECT * FROM (
SELECT 
    *,
    ROW_NUMBER()
OVER (PARTITION BY  ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference) AS row_num
FROM
    houses) AS temp_table WHERE row_num > 1) AS temp_table2);
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

SELECT * FROM houses;

ALTER TABLE houses 
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;

