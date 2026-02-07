from sqlalchemy import create_engine

def get_engine():
    """
    Returns SQLAlchemy engine connected to MySQL techmart_db
    """

    engine = create_engine(
        "mysql+mysqlconnector://root:Test_12345678@localhost:3306/techmart_db"
    )

    return engine