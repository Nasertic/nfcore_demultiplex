import json
import os
import sys

from sample_sheet import SampleSheet

file = "SampleSheet.csv"

def check_for_data_section(file_name:str):
    try:
        SampleSheet(file_name)
        return file_name
    except ValueError as e:
        if "Header for [Data] section is not allowed to have empty fields" in str(e):
            # Modify the sample sheet to remove that empty field from the Data header
            new_file = open("/home/projects/LAB/scripts/demultiplex_scripts/Demultiplex_enhanced/new_sample_sheet.csv", "w")
            with open(file_name) as file:
                lines = file.readlines()
                for i in range(len(lines)):
                    if i == 0:
                        new_file.write(lines[i])
                        continue
                    if lines[i-1].startswith("[Data]"):
                        # Remove last commas
                        lines[i] = lines[i].rstrip(",\n")
                        new_file.write(lines[i]+"\n")
                    else:
                        new_file.write(lines[i])

            return new_file.name


def parsing_sample_sheet(file_name, json_parsed_name="json_SampleSheet"):
    sample_sheet = SampleSheet(file_name)
    samples_file = open("samples.txt", "w")

    count = 1

    for sample in sample_sheet.samples:
        samples_file.write(f"{sample}_S{count}_R1_001.fastq.gz\n")
        samples_file.write(f"{sample}_S{count}_R2_001.fastq.gz\n")
        count += 1

    samples_file.close()

    with open(f"{json_parsed_name}.json", "w") as file:
        json.dump(json.loads(sample_sheet.to_json()), file, indent=4)

if __name__ == "__main__":
    sample_sheet = sys.argv[1]

    if "/mnt/SequencerOutput/" in sample_sheet:
        sample_sheet = sample_sheet.replace("/mnt/SequencerOutput/", "/data/medper/LAB/")

    sample_sheet = check_for_data_section(sample_sheet)
    parsing_sample_sheet(sample_sheet)

    if sample_sheet.startswith("/home/projects/LAB/scripts/demultiplex_scripts/Demultiplex_enhanced/"):
        os.remove(sample_sheet)
