# End to End ETL process in Microsoft Azure with Power BI analysis for web data

This repository presents a comprehensive data engineering solution using Azure platform tools. 
It is based on traffic accident and weather data in Toronto, which is retrieved from an API, and at the end of the process put into an Azure SQL Database.
The project closes with an analysis and dashboard done in Power BI.
The process leverages a combination of tools and services including Azure Data Factory, Azure Data Lake Storage, PySpark, Azure SQL Database and Power BI.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Data Used](#data-used)
- [Implementation](#implementation)
- [End Note](#end-note)

## Overview

The goal of this project is to showcase how to ingest, process, and analyse Toronto's traffic collisions and weather data using Azure services. The ETL process involves extracting data from web to Azure Data Lake Storage, transforming it using Azure Databricks and putting the processed data into a Azure SQL Database as data warehouse. At the end, a report was created using Power BI based on data from DWH.

My objectives for this project included:

- Building a basic understanding of data engineering and pipeline development based on Microsoft Azure
- Getting practical experience working with the Azure platform and its various services
- Delivering a fully functional and reliable final product that can be highlighted in my portfolio
  
## Architecture

The data flow architecture for this project looks as follows:

![Azure Data Engineering architecture diagram](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/assets/Azure_Data_Engineering_architecture_diagram.png)

- Azure Data Lake Storage: This centralized data lake repository stores both structured and unstructured data, built on Azure Blob Storage to support big data analytics.

- Azure Data Factory (ADF): A fully managed, serverless data integration service that enables the creation of data pipelines for ELT (Extract, Load, Transform) processes.

- Azure Databricks: Built on Apache Spark, is a managed big data analytics platform. It allows users to perform data transformation, analytics, and machine learning with Jupyter notebooks, leveraging Apache Spark's capabilities.

- Azure SQL Database: A fully managed, intelligent, and scalable relational database service. It is a platform-as-a-service (PaaS) offering, which means that Microsoft handles the majority of the database management and maintenance tasks, allowing users to focus on development.

- Azure Key Vault: A secure cloud service for managing cryptographic keys, secrets, and certificates. It provides centralized, secure storage and controlled access to sensitive information used by applications and services.

- Microsoft Entra ID: This cloud-based identity and access management service secures access to resources with identity management, authentication, and authorization capabilities.

- Microsoft Power BI: Robust business intelligence platform that enables data visualization, transformation, and sharing of insights. It connects to numerous data sources, creating interactive reports and dashboards that help organizations make data-driven decisions and gain insights.


## Data Used

- Toronto traffic collision data provided by Toronto Police Service Public Safety Data Portal and its API. This dataset includes all Motor Vehicle Collision (MVC) occurrences by their occurrence date and related offences from 2014 to now. The MVC categories include property damage (PD) collisions, Fail to Remain (FTR) collisions, injury collisions and fatalities. Dataset is updated constantly. More details about the data on this [website](https://data.torontopolice.on.ca/datasets/TorontoPS::traffic-collisions-open-data-asr-t-tbl-001/about). In the ETL pipeline, the following API was directly queryed with appropratie parameters: [https://services.arcgis.com/S9th0jAJ7bqgIRjw/arcgis/rest/services/Traffic_Collisions_Open_Data/FeatureServer/0/query](https://services.arcgis.com/S9th0jAJ7bqgIRjw/arcgis/rest/services/Traffic_Collisions_Open_Data/FeatureServer/0/query).
  
- Toronto weather data provided by [Open-Meteo API](https://open-meteo.com/en/docs/historical-weather-api). In this project, daily weather information was used, and the dataset contains, among others: temperature_2m_max (maximum daily air temperature at 2 meters above ground) or precipitation_sum(Sum of daily precipitation, including rain, showers and snowfall). The dataset is updated daily.

## Implementation

### Microsoft Azure:
1. Creating a main resource group needed to develop a solution. It was given the name: Traffic_collision_and_weather_in_toronto_DE_project. It will store all necessary azure services.
![Azure Data Engineering resource group](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/assets/Azure_main_resource_group.png)

2. Creating a storage account named torontodatalakestorage with hierarchical namespace enabled(This option convert service in Azure Data Lake Storage). Then, a toronto-data container is defined in the space, where the raw and transformed data will be stored in the corresponding folders.
![Azure Data Engineering azure data lake storage](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/assets/Azure_data_lake_storage.png)

3. Setting of the Azure Key Vault called Toronto-project-DE-keys to store the following secret-keys:
    - databricks-token - It is used by Azure Data Factory to safely connect with Databricks service using token authentication option.
    - Toronto-DWH-admin-password - Directly used in Azure Data Factory when connecting to Azure SQL Database (Toronto-DWH) with password authentication. 
    - Toronto-DWH-powerbi-analyst-user-password - Stored password for Azure SQL Database technical user (Toronto-DWH) to remember credentials. Not used directly in any service
    - torontodatalakestorage-key - It is used by Azure Data Factory and Databricks to safely connect with main Azure Data Lake Storage service using key.
  The permission model in the access configuration setting has been changed to Vault access policy. In the access policy option, the Databricks and Data Factory services.

4. Establishing an Azure Databricks service called Toronto_weather_traffic_collision_data_transform_databricks, where the Clean_transform_Toronto_data notebook is executed. The service has configured a secret scope called toronto key_vault_secret that allows you to retrieve a key from Azure Key Vault to securely connect to Azure Data Lake Storage.
![Azure Data Engineering azure databricks](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/assets/Azure_databricks.png)

5. Creating a Azure SQL Database ("Toronto_DWH") within a SQL server named toronto-dwh-server. Initially, Synapse Analytics was supposed to be configured as DWH, but after verifying the needs and comparing the costs, it was decided to use Azure SQL Database as a place to store the ready data. The service was configured with serverless compute tier using the following documentation: [https://learn.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview?view=azuresql&tabs=general-purpose](https://learn.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview?view=azuresql&tabs=general-purpose).

6. Setting up an Azure Data Factory called Traffic-Collision-Weather-Toronto-ETL and developing the following ETL pipeline:
![Azure Data Engineering Azure_data_factory_data_pipeline](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/assets/Azure_data_factory_data_pipeline.png)

    - I. Web activity (Get number of traffic collision records) - By executing the appropriate query to the API, the number of records about traffic accidents in Toronto was extracted in order to properly configure the data extraction process in the following steps.

    - II. Set variable activity (Set request range for traffic collision) - Based on the previous step, define the request_range variable, which will store a list from 0 to the integer part with the number of records divided by 2000 (the maximum number of records returned by a single request to the API)

    - III.a. ForEach activity (For Each offset records) performing Copy data activity (Toronto_traffic_collisions_copy) - In the loop, a query is executed to the corresponding API with traffic accident data, which outputs 2000 subsequent records each time based on the request range(multiplied by 2000) variable and used in the query in the ResultOffset parameter. The following data is dumped in parts in json format to the subfolder toronto_traffic_collisions_yyyMMdd(job date) in raw folder in Azure Data Lake Storage. An example of the extracted data has been placed in the repository [here](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/tree/main/data/raw/toronto_traffic_collisions_20241104)

    - III.b. Copy data activity (Toronto_weather_copy) - Retrieving Toronto weather data from the Open-Meteo API using the appropriate parameters and saving in csv format in the toronto_weather_yyyMMdd(job date) subfolder in raw folder in Azure Data Lake Storage. An example of the extracted data has been placed in the repository [here](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/data/raw/toronto_weather_20241104.csv)

    - IV. Notebook (Toronto_data_transform_notebook) - Cleaning and transformation of raw data using the Databricks platform, on which a notebook was developed with executable scripts written with the PySpark tool. The entire notebook with code has been saved in the repository [here](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/scripts/Databricks_clean_transform_Toronto_data_notebook.ipynb). Finally, the processed data was placed in Azure Data Lake Storage in .parquet format in transformed's folder in appropriate subfolders with the assigned date of job execution in yyyMMdd format. An example of the saving [here](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/tree/main/data/transformed).

    - V.a. Copy data activity (Copy_Toronto_weather_transformed_to_Azure_SQL) - Getting the prepared Toronto weather data from Azure Data Lake Storage and putting it into FCT_Weather table in Azure SQL Database service created earlier. This activity has an option to auto-create a table on execution, which has been enabled in this case. Also each time this step in the pipeline is run, the following pre-copy script is executed: "IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FCT_Weather') TRUNCATE TABLE dbo.FCT_Weather;". This removes existing data from the table preventing duplication.

    - V.b. Copy data activity (Copy_Toronto_traffic_collisions_transformed_to_AzureSQL) - Getting the prepared Toronto traffic collisions data from Azure Data Lake Storage and putting it into FCT_Traffic_Collisions table in Azure SQL Database service created earlier. This activity has an option to auto-create a table on execution, which has been enabled in this case. Also each time this step in the pipeline is run, the following pre-copy script is executed: "IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FCT_Traffic_Collisions') TRUNCATE TABLE dbo.FCT_Traffic_Collisions;". This removes existing data from the table preventing duplication.

    - VI. Script activity (Create_calendar_table_in_AzureSQL) - A SQL script is executed that creates a Date Dimension Table called DIM_Date, which contains a continuous range of dates based on min and max date from FCT_Traffic_Collisions table. Table stores various date attributes, for example, Year, Quarter, Month, Day name, Day of week , Is weekend? and more. The whole script is saved in the repository [here](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/scripts/Create_calendar_table_in_Azure_SQL_database.sql).

All of the above steps can be quickly replicated with the help of Azure Resource Manager(ARM) templates, which are json format objects that, using declarative syntax, define the resources to be deployed and the properties of those resources. This makes it possible to recreate the infrastructure and speed up the process of configuring the entire project. For this project, the ARM structures can be found at this [location](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/tree/main/Azure_templates).
            
### Microsoft Power BI:

1. Following best practices, a technical account was created in Azure SQL Database (Toronto-DWH) with the ability to read data for Power BI purposes. The script to create an account was saved in the [repository](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/scripts/Create_power_bi_analyst_user_in_azuresql_toronto_dwh.sql), removing its own unique password beforehand.

2. In Power BI Desktop, a connection to the source - Azure SQL Database has been defined using the server name and database and then authorized using the credentials of the technical account.
![Power_BI_source_connection](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/assets/PowerBI_source_connection.png)

3. All three datasets from the Toronto-DWH database were loaded into the data model and the following relationships between the data were defined:
![Power_BI_data_relationship](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/assets/PowerBI_data_relationship.png)

4. As a result of the analysis, modifying the data model and using several visualizations, the following dashboard was created:
![Power_BI_report_view](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/assets/PowerBI_report_view.png)

The Power BI file with the configured connection to the database, the prepared data model and selected visualizations was saved in the [repository](https://github.com/uminskib/Toronto_traffic_collisions_and_weather_Azure_Data_Engineering/blob/main/Toronto_traffic_collisions_and_weather_analysis.pbix). 

## End Note

- This project provides a great overview to many of Azure services such as Azure Data Factory or Azure Databricks.
- It would probably be sufficient for the tasks in this project to use only Azure Data Factory and Power BI capabilities. But as part of the self-study and to show possible approaches to larger, real-world business problems, more applications were used, such as Databricks.
- In the context of future development of the project, it is possible to further statistically analyze the data and use the capabilities of the Azure Machine Learning service to create a model predicting the number of traffic collisions.
