.PHONY: quality style

check_dirs := scripts src #setup.py

quality:
	poetry run ruff check $(check_dirs)

style:
	poetry run ruff --format $(check_dirs)

test:
	CUDA_VISIBLE_DEVICES= poetry run pytest tests/
