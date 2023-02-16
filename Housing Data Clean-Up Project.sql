USE SQL_Portfolio ;
GO

SELECT*
FROM NashvilleHousing

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Changing the Date Format in "SaleDate" fromm DateTime to Date format

ALTER TABLE NashvilleHousing
ADD SaleDate_2 Date;

UPDATE NashvilleHousing
SET SaleDate_2 = CONVERT(Date, SaleDate)


------------------------------------------------------------------------------------------------------------------------------------------------------

-- Here I create a new column based on the OwnerName column.
	--Since some homes are owned by two or three people, and some are owned by one person, I wanted to have a column indicating that, This informaion can be usefull

SELECT OwnerName,
	CASE 
		WHEN OwnerName LIKE '%&%' THEN 'Multiple Owners'
		WHEN OwnerName NOT LIKE '%&%' THEN 'Single Owner'
		ELSE OwnerName 
	END As [Single/Multiple Owners]
FROM NashvilleHousing

--Update the table
ALTER TABLE NashvilleHousing
ADD #Owners nvarchar (255) ;

UPDATE NashvilleHousing
SET #Owners = CASE 
		WHEN OwnerName LIKE '%&%' THEN 'Multiple Owners'
		WHEN OwnerName NOT LIKE '%&%' THEN 'Single Owner'
		ELSE OwnerName 
	END

--SELECT COUNT(CASE WHEN #Owners LIKE 'Single Owner' THEN 1 END) as [Single Owners],
--	COUNT(CASE WHEN #Owners LIKE 'Multiple Owners' THEN 1 END) as [Multiple Owners],
--	COUNT(OwnerName)
--FROM NashvilleHousing


------------------------------------------------------------------------------------------------------------------------------------------------------

--Populate Property Adress:
	--Since the property adress does not change, we can populate empty values if with a refernce point.
	--That refrence point here is that the ParcelID is associated with a PropertyAdress
			--So we can use the ParcelID with an Adress associated to them to populate 
				--the NULL PropertyAdress with the same ParcelID

SELECT PropertyAddress
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

SELECT a.ParcelID, 
		a.PropertyAddress, 
		b.ParcelID, 
		b.PropertyAddress,
		ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL


------------------------------------------------------------------------------------------------------------------------------------------------------

--Breaking the Adress into separate columns of Address, City, and State, using the delimiter:
		--First I will use the SUBSTRING Method to parse through the Property Adress and split it into Adress and City
		--Then I will use the PARSENAME statement that use the period (".") delimiter to split strings

--SUBSTRING *********

SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

		--Update the Table with the new columns
ALTER TABLE NashvilleHousing
ADD 
	[Property_Address] nvarchar (255)
	,[Property_City] nvarchar (255) ;
UPDATE NashvilleHousing
SET 
	Property_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)
	,Property_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


--PARSENAME********
SELECT OwnerAddress
FROM NashvilleHousing

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
	,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
	,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

	--Update the Table with the new columns
ALTER TABLE NashvilleHousing
ADD	[Owner_Address] nvarchar (255)
	,[Owner_City] nvarchar (255)
	,[Owner_State] nvarchar (255);
UPDATE NashvilleHousing
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
	,Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
	,Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


------------------------------------------------------------------------------------------------------------------------------------------------------

--Here I fix some of the reecords in the column "SoldAsVacant" which contains Yes/No responses
	--However, some of them are recorded as 'Y' for Yes and 'N' for No
	--So the below query fixes standarizes it to the most common recording method in the column: Yes/No

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END


------------------------------------------------------------------------------------------------------------------------------------------------------

--Removing duplicates:

-- After inspecting the data, some rows seem to be duplicates because they include the same records
-- The ROW_NUMBER function is used withe the Window Function PARTITION BY to identify the rows that are duplicates
-- Then a CTE table is used to SELECT filter the duplication by filtering using the Row_Number columns I created
-- Finally I delete the selected rows

--***This is a practice dataset, so removing the raw data is not a problem
		-- However, in the real world, one should not delete raw data (at least not without consultation with a senior)***


WITH Row_Num_CTE AS 
(
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID,
						 PropertyAddress,
						 SalePrice,
						 LegalReference
					ORDER BY
						UniqueID
						 ) AS Row_num
	FROM NashvilleHousing
)
DELETE
FROM Row_Num_CTE
WHERE Row_num > 1


------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove unnecessary columns
--***This is a practice dataset, so removing the raw data is not a problem
	-- However, in the real world, one should not delete raw data (at least not without consultation with a senior)**
--Here, I will drop the columns I split earlier (OwnerAddress and PropertyAddress), because I already made new columns from them
	-- Also, dropped the SaleDate column because I converted it Date Format from DateTime format (in a new column called SalDate_2)

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------



