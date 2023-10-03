def nevada(input_path):
    
    import pandas as pd
    from bs4 import BeautifulSoup

    table_id = "ctl04_mobjContributions_dgContributions"
    nv_df = pd.read_html(input_path, attrs = {"id": table_id}, header=0)[0]

    nv_df["full_name"] = nv_df[
        "NAME AND ADDRESS OF PERSON, GROUP OR ORGANIZATION WHO MADE CONTRIBUTION"
    ].apply(lambda x: " ".join(x.split()[:2]))
    nv_df["full_address"] = nv_df[
        "NAME AND ADDRESS OF PERSON, GROUP OR ORGANIZATION WHO MADE CONTRIBUTION"
    ].apply(lambda x: " ".join(x.split()[2:]).lower())

    nv_df = nv_df.rename(
        columns={
            "AMOUNT OF CONTRIBUTION": "donation_amount",
            "DATE OF CONTRIBUTION": "donation_date",
        }
    )

    nv_df.drop(
        columns=[
            "NAME AND ADDRESS OF PERSON, GROUP OR ORGANIZATION WHO MADE CONTRIBUTION",
            "CHECK HERE IF LOAN",
            "NAME AND ADDRESS OF 3rd PARTY IF LOAN GUARANTEED BY 3rd PARTY",
            "NAME AND ADDRESS OF PERSON, GROUP OR ORGANIZATION WHO FORGAVE THE LOAN, IF DIFFERENT THAN CONTRIBUTOR",
        ],
        inplace=True,
    )

    nv_df["donation_date"] = nv_df["donation_date"].apply(lambda x: "".join(x[:10]))
    nv_df["donation_amount"] = nv_df["donation_amount"].apply(
        lambda x: "".join(x.split("$")[-1])
    )
    nv_df["donation_amount"] = nv_df["donation_amount"].apply(
        lambda x: "".join(x.split(".")[0]).replace(",", "")
    )

    nv_df = nv_df[
        nv_df["full_name"].str.contains(r",|\.|\$|\&|\'|\d+", regex=True) == False
    ]
    nv_df["full_address"] = nv_df["full_address"].str.replace(r"^[^\d]*", "", regex=True)
    nv_df.drop_duplicates("full_name", inplace=True)

    return(nv_df)