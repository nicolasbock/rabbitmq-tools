import setuptools

setuptools.setup(
    name="RabbitMQ Test Tools",
    version="1.0.2",
    description="This is a test",
    long_description="...",
    long_description_content_type="text/markdown",
    author="Nicolas Bock",
    packages=setuptools.find_packages(),
    entry_points={
        "console_scripts": [
            "rabbitmq-tools = rabbitmqtools.main:main",
        ],
    }
)
