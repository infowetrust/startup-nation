cd ~/kauffman_neg


/***** Start of DEBUGGING ******/
set trace off
set tracedepth 1

/***** END of DEBUGGING ******/

capture log close 
capture log close masterlog

/* Clean the output folder before starting
 * Allows a clean output -- but could have secondary consecuences.
*/
* !rm "~/kauffman_neg/output/*"
 * !rm "~/kauffman_neg/output/graphs/*"


set linesize 250
set more off


/****** Switches  on which tasks to do
 ** Description
 ** build_dataset: If 1 then a new collapse is run on each raw file
 ** setup_analysis_file: If 1 then a new collapsed complete file is built.
 ** reduce_data_size: If 1 creates a new minimal file from the $completedatafile file
 ** build_model: Runs the models again by running Build_National_results.do
 ** test_by_state: Performs tests of the model by state
 ** k_fold_test: Runs the 10-fold test and stores the results
 ** do_monte_carlo: If 1, a Monte Carlo process is run to estimate new entrepreneurial quality models
 ** estimate_indexes: If 1 runs Index_Results.do and estimates the new indexes
 ** do_data_appendix: If 1 runs the file Data_Appendix.do  
 ** store_output: If 1 copies all output files to ~/kauffman_neg/output_iterations/$output_folder/
****/
      global build_dataset 0
      global setup_analysis_file 0
      global reduce_data_size 0
      global build_model 0
      global test_by_state 0
      global test_by_year 1
      global k_fold_test 0
      global do_monte_carlo 0
      global estimate_indexes 0
      global do_data_appendix 1
      global store_output 0


/*** Build Model Parameters ********
 ** Description 
 ** build_model_univariate
 ** build_model_preliminary
 ** build_main_model
 ** build_model_robustness
 ** results_summary_stats: Set to 0 if it should skip over the summary stats section
 **/

     global build_model_univariate 0
     global build_model_preliminary 0
     global build_main_model   0
     global build_model_robustness 1
     global build_model_employment 1
     global results_summary_stats 0

    
    /* Set to 1 if you wish to run models by state and year
     * BUG: Not sure if it works*/
    global quality_state_year 0


/**** Data Definitions
 **
 **/
     
     global new_states  
     global dataset_state_list IL WI OH NC MN NJ AR WY VA RI AZ NM ME ND IA KY UT SC CO TN VA RI ID MO OK CA FL MA WA TX NY WY AK OR GA MI VT 

     * BUG: I have no idea what this does anymore.
     global state_to_use

     /* 
      * The file on which all data is stored
      *    - Official is analysis34.collapsed.dta
      */
     global completedatafile analysis34.collapsed.dta
     global datafile analysis34.minimal.dta




/* this can change to have some special suffixes. Not usually changed */
global output_suffix 
global skip_states_in_indexes 

log using output/Master_$output_suffix.log, text name(masterlog) replace


/*** Monte Carlo Process Parameters ***/
    global num_monte_carlo_iterations 101
    /* Used if a monte carlo gets stuck and needs to be restarted. Else, set to 1 */
    global mc_start_iteration 1


/*** Debugging Options **/
    global verbose 1

global output_folder $model

** BUG: Does this even work by now? 
global model_params 


/* Do not Touch this ones */
    * BUG: I dont think this works anymore
    * It is very rare that you need to collapse the files again
    global collapse_files 0
    global collapse_new_states 0
    global build_new_training_sample 0







if $build_dataset == 1 {
    do proposal2/Build_National_Dataset.do
}

if $setup_analysis_file == 1 {
    do proposal2/Setup_Analysis_Datafile.do
}



if $build_new_training_sample == 1 {
    clear
    u $datafile, replace
    select_sample, trainingsample(~/kauffman_neg/SampleSelection.dta) maketrain savetrain
}

if $reduce_data_size == 1  {
    do proposal2/Reduce_Data_Size.do
}

if $build_model == 1{
    do proposal2/Build_National_results.do
}

if $k_fold_test == 1 {
   do proposal2/K_Fold_Model_Test.do
}

if $test_by_state == 1 | $test_by_year == 1 {
    do proposal2/Test_By_State_and_Year.do
}

if $do_monte_carlo == 1 {
    do proposal2/Monte_Carlo_Simulations.do
}



if $estimate_indexes == 1 {
    do ~/kauffman_neg/proposal2/Index_Results.do
}

if $do_data_appendix == 1 {
    do ~/kauffman_neg/proposal2/Data_Appendix.do
}

if $store_output == 1 {
    !mkdir ~/kauffman_neg/output_iterations/$output_folder
    !cp -R "~/kauffman_neg/output/*" ~/kauffman_neg/output_iterations/$output_folder/
}

log close masterlog
