#!/usr/bin/env python
# coding: utf-8

# In[31]:


import pandas as pd
from sqlalchemy import create_engine
from tqdm.auto import tqdm


# In[32]:


url_green = 'https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet'
url_zone = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv'


# In[33]:


engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')


# In[34]:


df_green = pd.read_parquet(url_green)


# In[35]:


df_green.to_sql('green_taxi_data', con=engine, if_exists="replace", chunksize=100000)


# In[36]:


df_green.head()


# In[37]:


df_zone = pd.read_csv(url_zone)


# In[38]:


df_zone.to_sql('taxi_zone_lookup', con=engine, if_exists="replace", chunksize=100000)


# In[39]:


df_zone.head()


# In[6]:





# In[ ]:





# In[ ]:





# In[ ]:




