import setuptools

setuptools.setup(
    name="RabbitMQ Test",
    verion="1",
    packages=setuptools.find_packages(),
    scripts=["test-rabbit.py"],
    entry_points={
        "console_scripts": [
            "rabbitmq-tools = rabbitmqtools.main:main",
        ],
    }
)
