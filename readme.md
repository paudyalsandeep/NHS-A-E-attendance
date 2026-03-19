# NHS A&E Data Cleaning & Consolidation Pipeline

##  Overview
This project builds a data pipeline to clean, standardize, and combine multi-year NHS A&E provider-level datasets into a single master dataset for analysis.

##  Data Source
Monthly Excel files (2018–2025) containing provider-level A&E statistics.

##  Features
- Automated batch processing of monthly files
- Handles multi-level Excel headers
- Cleans and standardizes column names
- Removes unnecessary percentage columns
- Filters invalid/missing records
- Combines all data into a single master dataset

##  Tech Stack
- Python
- Pandas
- Jupyter Notebook

##  Project Structure
Datasets/
Raw/
Cleaned/
master_dataset.csv

notebooks/
data_processing.ipynb

## How to Run
1. Place raw data in `Datasets/Raw/{year}/{month}.xls`
2. Run the notebook
3. Output:
   - Cleaned monthly files
   - `master_dataset.csv`

## Output
A consolidated dataset with:
- Provider-level A&E activity
- Monthly time series (2018–2025)
- Clean and analysis-ready structure

## Future Improvements
- Add data validation checks
- Automate pipeline with scheduling
- Load into SQL / dashboard tools