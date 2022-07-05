## FLO RFM Analysis & Data Preprocessing

import numpy as np
import pandas as pd
import datetime as dt


pd.set_option('display.max_columns',None)
##pd.set_option('display.max_rows',None)
pd.set_option('display.width',500)
pd.set_option('display.float_format',lambda x: "%.3f" %x)

#Examining data

flo_df = pd.read_csv("Datasets/flo_data_20k.csv")
flo_df.shape
flo_df.head()

flo_df_copy = flo_df.copy()

def dataprepocessing (df):
    df.head(10)
    df.columns
    df.describe().T
    df.isnull().sum()
    df.columns.dtype

    for col in df:
        print(str(col) + " " + str(df[col].dtypes))

    df["Total_Number_of_Purchases"] = df["order_num_total_ever_online"] + df["order_num_total_ever_offline"]

    df["Total_Shopping_Spend"] = df["customer_value_total_ever_offline"] + df[
        "customer_value_total_ever_online"]
    df["first_order_date"] = pd.to_datetime(df['first_order_date'])
    df["last_order_date"] = pd.to_datetime(df['last_order_date'])
    df["last_order_date_online"] = pd.to_datetime(df['last_order_date_online'])
    df["last_order_date_offline"] = pd.to_datetime(df['last_order_date_offline'])

    df.groupby("order_channel").agg({"Total_Number_of_Purchases":"sum","Total_Shopping_Spend":"sum"})
    df.sort_values(by="Total_Shopping_Spend", ascending=False).head(10)
    df.sort_values(by="Total_Number_of_Purchases", ascending=False).head(10)
    print(df.head())

dataprepocessing(flo_df)


##Calculating RFM Metrics

#Recency , Frequency ,Monetary

today = dt.datetime(2021,6,2)


flo_df["last_order_date"].max()
flo_df["Frequency"] = flo_df["Total_Number_of_Purchases"]
flo_df["Monetary"] = flo_df["Total_Shopping_Spend"]
flo_df["Recency"] = (today - flo_df["last_order_date"]).astype('timedelta64[D]')
flo_df["Recency2"] = (today - flo_df["last_order_date"]).dt.days
##flo_df["Recency1"].drop()
flo_df.head()

flo_df["Recency"].astype('timedelta64[D]')

rfm = pd.DataFrame()

rfm = flo_df[["master_id","Recency","Frequency","Monetary","interested_in_categories_12"]]

rfm.head()

## FLO Calculation of RF Score

rfm["Recency_Score"] = pd.qcut(rfm["Recency"],5,labels = [5,4,3,2,1])
rfm["Frequency_Score"] = pd.qcut(rfm["Frequency"].rank(method="first"),5,labels = [1,2,3,4,5])
rfm["Monetary_Score"] = pd.qcut(rfm["Monetary"],5,labels = [1,2,3,4,5])

rfm.head()

rfm["RF_Score"] = (rfm["Recency_Score"].astype(str) + rfm["Frequency_Score"].astype(str))

##Segment Identification

seg_map = {
    r'[1-2][1-2]': 'hibernating',
    r'[1-2][3-4]': 'at_Risk',
    r'[1-2]5': 'cant_loose',
    r'3[1-2]': 'about_to_sleep',
    r'33': 'need_attention',
    r'[3-4][4-5]': 'loyal_customers',
    r'41': 'promising',
    r'51': 'new_customers',
    r'[4-5][2-3]': 'potential_loyalists',
    r'5[4-5]': 'champions'
}

rfm["Segment"] = rfm["RF_Score"].replace(seg_map,regex=True)

##Final

rfm[["Segment","Recency","Frequency","Monetary"]].groupby("Segment").agg(["mean","count"])

rfm.loc[rfm.interested_in_categories_12.str.contains("KADIN")]

##Task 1 = (champions, loyal customers) and women shoppers
rfm_loyal_woman = rfm.loc[(rfm["Segment"].isin(["champions","loyal_customers"]) & rfm.interested_in_categories_12.str.contains("KADIN"))]

rfm_loyal_woman["master_id"].to_csv("Datasets/rfm_loyal_woman.py",index = False)


##Task 2 = about_to_sleep/ new_customers and men/child shoppers

rfm_loyal_boy_man = rfm.loc[(rfm["Segment"].isin(["about_to_sleep","new_customers","cant_loose"]) & rfm.interested_in_categories_12.str.contains("ERKEK") & rfm.interested_in_categories_12.str.contains("COCUK"))]
rfm_loyal_boy_man.head()

rfm_loyal_boy_man["master_id"].to_csv("Datasets/rfm_loyal_boy_man.py",index = False)

