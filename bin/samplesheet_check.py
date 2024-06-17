import os
import pathlib

from colorama import init
from sample_sheet import SampleSheet

init()

check_mark = "\u2713"
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"

translation_table = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
    'ü': 'u', 'Ü': 'U',
    'ñ': 'n', 'Ñ': 'N', 'ç': 'c', 'Ç': 'C',
    '´': '', '`':''
}




def warning_print(msg: str):
    print(f"\n{YELLOW}WARNING: {msg}{RESET}")


def error_print(msg: str):
    print(f"\n{RED}ERROR:\n\nSample sheet contains the following error: {msg}\n\n{RESET}")

def header_error_print():
    print(f"\n{RED}ERROR:{RESET}\n\nHeader for [Data] section is not allowed to have empty fields.\n\n\nYou have something like the following example:\n")
    print(f"{GREEN}[Data]\nSample_ID, Index_ID, Index, Index2, Sample_Project,{RED} EMTPY FIELD, EMPTY FIELD...\n\n{RESET}")

def success_section(section: str):
    print(f"\n{GREEN}{check_mark}\t[{section}]{RESET}")


def check_header(header: SampleSheet) -> bool:
    if header == []:
        error_print("La sección de [Header] no está presente")
        return False

    if "Date" not in header:
        error_print('El campo "Date" no está presente')
        return False

    if "Investigator Name" not in header:
        error_print('El campo "Investigator Name" no está presente')
        return False

    if "Experiment Name" not in header:
        error_print('El campo "Experiment Name" no está presente')
        return False

    if "Description" not in header:
        error_print('El campo "Description" no está presente')
        return False

    for header_field, header_value in header.items():
        if header_value == "" or header_value == " ":
            warning_print(f'El campo "{header_field}" está vacío')

    success_section("Header")
    return True


def check_settings(settings: SampleSheet) -> bool:
    if settings == []:
        error_print("La sección de [Settings] no está presente")
        return False

    if "AdapterRead1" not in settings:
        error_print('El campo "AdapterRead1" no está presente')
        return False

    if "AdapterRead2" not in settings:
        error_print('El campo "AdapterRead2" no está presente')
        return False

    for settings_field, settings_value in settings.items():
        print(settings_field)
        if settings_field == "AdapterRead1" or settings_field == "AdapterRead2":
            if not correct_index(settings_value):
                raise ValueError("ACTG error") #TODO
        if settings_value == "":
            warning_print(f'El campo "{settings_field}" está vacío')

    success_section("Settings")
    return True


def check_reads(reads: SampleSheet) -> bool:
    if reads == []:
        warning_print("La sección de [Reads] no está presente")
        return True

    if len(reads) < 2:
        warning_print("El run es single-end?")

    if len(reads) > 2:
        error_print("Mas de dos campos en la sección de [Reads]")
        return False

    success_section("Reads")
    return True


def check_data(data: SampleSheet) -> bool:
    for sample in data:
        sample_id = getattr(sample, "Sample_ID")
        index1 = getattr(sample, "index")
        index2 = getattr(sample, "index2")

        if not correct_name(sample_id):
            error_print(f'El nombre de la muestra "{sample_id}" contiene caracteres no permitidos')
            return False

        if not correct_index2(index1, index2):
            error_print(
                f'El índice 2 ("{index2}") de la muestra "{sample_id}" no tiene el mismo tamaño que su índice 1 ("{index1}")'
            )
            return False

    success_section("Data")
    return True


# Check if sample name contains anything else than numbers / characters / "_" / "-"
def correct_name(sample: str) -> bool:
    return all(c.isalnum() or c == "_" or c == "-" for c in sample)


# Check if index contains only A, C, G, T
def correct_index(index: str) -> bool:
    return all(c in "ACGT" for c in index)


# Check that index1 and index2 have the same length and that index2 only contains A, C, G and T
def correct_index2(index1: str, index2: str) -> bool:
    return len(index1) == len(index2) and correct_index(index2)


def check_samplesheet(file: str):
    try:
        sample_sheet = SampleSheet(file)

        if not check_header(sample_sheet.Header):
            return

        if not check_settings(sample_sheet.Settings):
            return

        if not check_reads(sample_sheet.Reads):
            return

        if not check_data(sample_sheet.samples):
            return

        else:
            print(f"\n{GREEN}La sample sheet está bien!\n\n{RESET}")

    except ValueError as e:
        if "Header for [Data] section is not allowed to have empty fields" in str(e):
            header_error_print()
            return
        raise ValueError(e)

def convert_to_correct_characters(line: str) -> str:
    new_line = []
    for char in line:
        new_line.append(translation_table.get(char, char))

    return ''.join(new_line).replace(";", ",")

def change_invalid_characters(file: str):
    new_file = []
    with open(file) as f:
        for line in f:
            new_line = convert_to_correct_characters(line)
            new_file.append(new_line)

    with open(file, "w") as f:
        f.writelines(new_file)

if __name__ == "__main__":
    sample_sheet_file = ""
    parent_dir = pathlib.Path(__file__).parent.resolve()
    for file in os.listdir(parent_dir):
        if file == "samplesheet_check.py":
            continue

        if file.endswith(".csv") and sample_sheet_file != "":
            error_print("Hay más de un archivo .csv en el directorio")
            exit()

        if file.endswith(".csv") and sample_sheet_file == "":
            sample_sheet_file = file

    change_invalid_characters(f"{parent_dir}/{sample_sheet_file}")
    check_samplesheet(f"{parent_dir}/{sample_sheet_file}")




## TODO UMIs, Index different length, index bigger length warning, characters Ns..
## Check other csv formats -> LF, CRLF, UTF-...
## Same index on different samples
## CHECK INDEX ID with index
