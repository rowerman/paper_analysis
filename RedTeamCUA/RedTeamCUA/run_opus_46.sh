#!/bin/bash
mkdir run_all_logs
exec > >(tee "run_all_logs/run_all_output_$(date +'%Y-%m-%d_%H-%M-%S').log") 2>&1

# for calling anthropic bedrock, this is different from calling aws ec2.
export AWS_ACCESS_KEY='<YOUR_AWS_ACCESS_KEY>'
export AWS_SECRET_KEY='<YOUR_AWS_SECRET_KEY>'

# for creating an EC2 instance
export AWS_ACCESS_KEY_EC2='<YOUR_AWS_ACCESS_KEY_FOR_EC2>'
export AWS_SECRET_KEY_EC2='<YOUR_AWS_SECRET_KEY_FOR_EC2>'

export AWS_REGION='<YOUR_AWS_REGION>'


export AZURE_API_KEY='<YOUR_AZURE_API_KEY>'
export AZURE_RESOURCE_NAME='<YOUR_AZURE_RESOURCE_NAME>'
export AZURE_API_VERSION='<YOUR_AZURE_API_VERSION>'
export AZURE_ENDPOINT='<YOUR_AZURE_ENDPOINT>'

export AZURE_API_VERSION_FOR_SECOND_CALL='<YOUR_AZURE_API_VERSION_FOR_SECOND_CALL>'
export AZURE_ENDPOINT_FOR_SECOND_CALL='<YOUR_AZURE_ENDPOINT_FOR_SECOND_CALL>'

# for RocketChat npc
export AZURE_OPENAI_API_KEY='<YOUR_AZURE_API_KEY>'
export AZURE_MODEL_FOR_ROCKETCHAT_NPC='<YOUR_AZURE_MODEL>'


provider=$1
test_all_meta_path=$2
test_config_base_dir=$3
adv_task=$4
max_steps=$5
results_dir=${6:-"results_for_opus_46"}
rep_time=${7:-"1"}


if [ -z "$provider" ]; then
    echo "input the provider (aws or vmware):"
    read provider
fi


if [ "$provider" != "aws" ] && [ "$provider" != "vmware" ]; then
    echo "Error: provider must be 'aws' or 'vmware'"
    exit 1
fi

start_time=$(date +"%Y-%m-%d %H:%M:%S")



# us.anthropic.claude-sonnet-4-20250514-v1:0
# us.anthropic.claude-sonnet-4-5-20250929-v1:0
# us.anthropic.claude-opus-4-20250514-v1:0
# global.anthropic.claude-opus-4-5-20251101-v1:0

cua_models=(
    "aws | global.anthropic.claude-opus-4-6-v1 | cua"
)

# cua_observations_type=("screenshot" "screenshot_a11y_tree")
cua_observations_type=("screenshot")

# max_steps=50
repetitions=$rep_time
start=1

pids=()

for (( i=$start; i<=$repetitions; i++ )); do
    for model in "${cua_models[@]}"; do
        for observation in "${cua_observations_type[@]}"; do
            if [ "$provider" == "vmware" ]; then
                echo "execute: python run.py --headless --provider_name vmware --path_to_vm ./vmware_vm_data/Ubuntu0/Ubuntu0.vmx --observation_type $observation --model '$model' --result_dir ./$results_dir/adv_results_$i --test_all_meta_path $test_all_meta_path --max_steps $max_steps"
                python run.py --headless --provider_name vmware --path_to_vm ./vmware_vm_data/Ubuntu0/Ubuntu0.vmx --observation_type "$observation" --model "$model" --result_dir "./$results_dir/adv_results_$i" --test_all_meta_path "$test_all_meta_path" --test_config_base_dir $test_config_base_dir --max_steps $max_steps
            elif [ "$provider" == "aws" ]; then
                # echo 'It will skip injection'
                # echo 'It will skip injection'
                # echo 'It will skip injection'
                # python run.py --headless --provider_name aws --observation_type "$observation" --model "$model" --result_dir "./$results_dir/adv_results_$i" --test_all_meta_path "$test_all_meta_path" --test_config_base_dir $test_config_base_dir --max_steps $max_steps --aws_ami $adv_task --agent_type PromptAgent --skip_injection &
                # pids+=($!)

                # skip injection
                # echo -e '\033[31mIt will skip injection\033[0m'
                # echo -e '\033[31mIt will skip injection\033[0m'
                # echo -e '\033[31mIt will skip injection\033[0m'
                
                python run.py --headless --provider_name aws --observation_type "$observation" --model "$model" --result_dir "./$results_dir/adv_results_$i" --test_all_meta_path "$test_all_meta_path" --test_config_base_dir $test_config_base_dir --max_steps $max_steps --aws_ami $adv_task --agent_type PromptAgent &
                pids+=($!)
                
            fi
        done
    done
done


if [ ${#pids[@]} -gt 0 ]; then
    wait "${pids[@]}"
    echo "All background processes have completed"
    echo "Process status:"
    ps -p ${pids[*]} -o pid,ppid,cmd,stat
fi

end_time=$(date +"%Y-%m-%d %H:%M:%S")

echo "start time: ${start_time}"
echo "end time: ${end_time}"