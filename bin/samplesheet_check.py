import os

from colorama import init
from sample_sheet import SampleSheet

init()

check_mark = '\u2713'
GREEN   = '\033[92m'
RED     = '\033[91m'
YELLOW  = '\033[93m'
RESET   = '\033[0m'


def warning_print(msg: str):
    print(f"\n{YELLOW}WARNING: {msg}{RESET}")

def error_print(msg: str):
    print(f"\n{RED}ERROR:\n\nSample sheet contains the following error: {msg}\n\n{RESET}")

def success_section(section: str):
    print(f"\n{GREEN}{check_mark}\t[{section}]{RESET}")

def check_header(header: SampleSheet) -> bool:
    if header == []:
        error_print("La sección de [Header] no está presente")
        return False

    if "Date" not in header:
        error_print("El campo \"Date\" no está presente")
        return False

    if "Investigator Name" not in header:
        error_print("El campo \"Investigator Name\" no está presente")
        return False

    if "Experiment Name" not in header:
        error_print("El campo \"Experiment Name\" no está presente")
        return False

    if "Description" not in header:
        error_print("El campo \"Description\" no está presente")
        return False

    for header_field, header_value in header.items():
        if header_value == "":
            warning_print(f"El campo \"{header_field}\" está vacío")

    success_section("Header")
    return True

def check_settings(settings: SampleSheet) -> bool:
    if settings == []:
        error_print("La sección de [Settings] no está presente")
        return False

    if "AdapterRead1" not in settings:
        error_print("El campo \"AdapterRead1\" no está presente")
        return False

    if "AdapterRead2" not in settings:
        error_print("El campo \"AdapterRead2\" no está presente")
        return False

    for settings_field, settings_value in settings.items():
        if settings_value == "":
            warning_print(f"El campo \"{settings_field}\" está vacío")

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
        sample_id   = getattr(sample, 'Sample_ID')
        index1      = getattr(sample, 'index')
        index2      = getattr(sample, 'index2')

        if not correct_name(sample_id):
            error_print(f"El nombre de la muestra \"{sample_id}\" contiene caracteres no permitidos")
            return False

        if not correct_index2(index1, index2):
            error_print(f"El índice 2 (\"{index2}\") de la muestra \"{sample_id}\" no tiene el mismo tamaño que su índice 1 (\"{index1}\")")
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
        raise ValueError(e)


if __name__ == "__main__":
    sample_sheet_file = ""
    for files in os.listdir():
        if files == "samplesheet_check.py":
            continue

        if files.endswith(".csv") and sample_sheet_file != "":
            error_print("Hay más de un archivo .csv en el directorio")
            exit()

        if files.endswith(".csv") and sample_sheet_file == "":
            sample_sheet_file = files


    check_samplesheet(sample_sheet_file)
