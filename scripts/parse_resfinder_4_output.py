# To run this file use the command
# python3 parse_resfinder_4_output.py <SPACE SEPARATED LIST OF IDS> <PATH TO RESFINDER 4 OUTPUT DIR> <SPECIES NAME>
# e.g python3 parse_resfinder_4_output.py 'sample1 sample2 sample3' output_dir 'staphylococcus_aureus'
import csv
import sys
import os

def read_pheno_table(filepath):
    with open(filepath) as f:
        reader = csv.reader(f, delimiter='\t')
        # skip headers
        for _ in range(17):
            next(reader)
        
        # get resistance and sensitive phenotypes
        results = {'resistant' : [], 'sensitive' : []}
        for row in reader:
            if len(row) == 5:
                antimicrobial = row[0]
                phenotype = row[2]
                
                if 'Resistant' in phenotype:
                    results['resistant'].append(antimicrobial)
                elif 'No resistance' in phenotype:
                    results['sensitive'].append(antimicrobial)
        return results

def add_single_results_to_sample_results(id, result, sample_results):
    for result_type in [('resistant', 'R'), ('sensitive', 'S')]:
        for antimicrobial in result[result_type[0]]:
            if antimicrobial not in sample_results:
                sample_results[antimicrobial] = {}
            sample_results[antimicrobial][id] = result_type[1]


def write_out_summary_file(file_type, antimicrobial_results, ids_with_results):
    with open(f'{file_type}_summary.tsv', 'w') as outfile:
        headers = '\t'.join(sorted(antimicrobial_results.keys()))
        outfile.write(f'sample\t{headers}\n')
        for id in sorted(ids_with_results):
            sample_results = []
            for antimicrobial in sorted(antimicrobial_results.keys()):
                sample_results.append(antimicrobial_results[antimicrobial][id])
            # write out data
            sample_result_string = '\t'.join(sample_results)
            outfile.write(f'{id}\t{sample_result_string}\n')


# set up result dicts
species_specific_antimicrobial_results = {}
full_antimicrobial_results = {}

# get ids from string
ids_string = sys.argv[1]
ids = ids_string.split(' ')

# set base dir for resfinder 4 outputs
result_base_path = sys.argv[2]

# specifiy species
species = sys.argv[3]

# for each result get R/S values and add to dicts which will eventually be written to tsv files
ids_with_results = []
for id in ids:
    species_result_file = f'{result_base_path}/{id}/pheno_table_{species}.txt'
    full_result_file = f'{result_base_path}/{id}/pheno_table.txt'
    if os.path.exists(species_result_file) and os.path.exists(full_result_file):
        ids_with_results.append(id)
        species_result = read_pheno_table(species_result_file)
        full_result = read_pheno_table(full_result_file)
        add_single_results_to_sample_results(id, species_result, species_specific_antimicrobial_results)
        add_single_results_to_sample_results(id, full_result, full_antimicrobial_results)

write_out_summary_file('species_specific', species_specific_antimicrobial_results, ids_with_results)
write_out_summary_file('full', full_antimicrobial_results, ids_with_results)
