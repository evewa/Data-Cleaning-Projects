
-- Data cleaning project, Guided by Alex the Analyst

SELECT *
FROM nashvillehousing

-- standardize SaleDate information

SELECT SalesDateStandardized, CONVERT(Date,SaleDate) 
FROM nashvillehousing -- its YYYY-MM-DD HH:MM:SS.SSS-- change that to short datetime format through CONVERT

ALTER TABLE nashvillehousing
ADD SalesDateStandardized Date

Update nashvillehousing
SET SalesDateStandardized = CONVERT(Date,SaleDate) 

-- Next is Property Address, noticed in the first 1000 rows there was a null

SELECT *
FROM nashvillehousing
WHERE  PropertyAddress is null -- 29 nuill values, dont know the 'why' so look at the rest of the data
ORDER BY ParcelID


SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) -- joined a table to itself, basically saying "if the id is the same, and the unique ID ISNT the same (i.e. not the same row), and if the address is null, replace it with the OTHER matching ID's address
FROM nashvillehousing a
JOIN nashvillehousing b ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM nashvillehousing a
JOIN nashvillehousing b ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Now that address is fixed, turn it into columns and separate out the data between address, city and state
SELECT 
SUBSTRING(PropertyAddress, 1, charindex(',',PropertyAddress)-1) AS Address, 
SUBSTRING(PropertyAddress, charindex(',',PropertyAddress) +1, LEN(PropertyAddress)) AS City

FROM nashvillehousing

ALTER TABLE nashvillehousing
ADD PropertySplitAddress NVARCHAR(255)

Update nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, charindex(',',PropertyAddress)-1)

ALTER TABLE nashvillehousing
ADD PropertySplitCity NVARCHAR(255)

Update nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, charindex(',',PropertyAddress) +1, LEN(PropertyAddress))

-- Now do the same for Owner Address, there are periods in this column so we can actually use  PARSENAME and replace the first comma with a period


SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM nashvillehousing

ALTER TABLE nashvillehousing
ADD OwnerSplitAddress Nvarchar(255);

Update nashvillehousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE nashvillehousing
ADD OwnerSplitCity Nvarchar(255);
Update nashvillehousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE nashvillehousing
ADD OwnerSplitState Nvarchar(255);
Update nashvillehousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

SELECT *
FROM nashvillehousing

-- Standardizing responses in SoldAsVacant, choosing Yes and No as mains as there are more using it as a response

SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant, 
case WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM nashvillehousing

update nashvillehousing
SET SoldAsVacant = case WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

-- Remove duplicates, its not standard practice to delete data in your raw database but for the sake of the project we will..
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) row_num
FROM nashvillehousing
)

SELECT * --DELETE
FROM RowNumCTE
Where row_num>1


-- Remove unused columns, again, I prefer not to touch the raw data as its not standard practice. In actual work You would likely need to talk to a couple people before doing this.

ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE nashvillehousing
DROP COLUMN SaleDate

SELECT * 
FROM nashvillehousing