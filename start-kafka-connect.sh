#!/bin/bash -e

if [[ -z "$CONNECT_BOOTSTRAP_SERVERS" ]]; then
    echo "ERROR: missing mandatory config: CONNECT_BOOTSTRAP_SERVERS"
    exit 1
fi

if [[ -z "$KAFKA_LOG_DIRS" ]]; then
    export KAFKA_LOG_DIRS="/kafka/kafka-logs-$HOSTNAME"
fi

if [[ -n "$KAFKA_HEAP_OPTS" ]]; then
    sed -r -i 's/(export KAFKA_HEAP_OPTS)="(.*)"/\1="'"$KAFKA_HEAP_OPTS"'"/g' "$KAFKA_HOME/bin/connect-distributed.sh"
    unset KAFKA_HEAP_OPTS
fi

# Take /usr/share/java/connectors automatically
export CONNECT_PLUGIN_PATH:${CONNECT_PLUGIN_PATH:-/usr/share/java/connectors}

#Issue newline to config file in case there is not one already
echo "" >> "$KAFKA_HOME/config/connect-distributed.properties"

(
    function updateConfig() {
        key=$1
        value=$2
        file=$3

        # Omit $value here, in case there is sensitive information
        echo "[Configuring] '$key' in '$file'"

        # If config exists in file, replace it. Otherwise, append to file.
        if grep -E -q "^#?$key=" "$file"; then
            sed -r -i "s@^#?$key=.*@$key=$value@g" "$file" #note that no config values may contain an '@' char
        else
            echo "$key=$value" >> "$file"
        fi
    }

    # Read in env as a new-line separated array. This handles the case of env variables have spaces and/or carriage returns. See #313
    IFS=$'\n'
    for VAR in $(env)
    do
        env_var=$(echo "$VAR" | cut -d= -f1)

        if [[ $env_var =~ ^CONNECT_ ]]; then
            connect_name=$(echo "$env_var" | cut -d_ -f2- | tr '[:upper:]' '[:lower:]' | tr _ .)
            updateConfig "$connect_name" "${!env_var}" "$KAFKA_HOME/config/connect-distributed.properties"
        fi

        if [[ $env_var =~ ^LOG4J_ ]]; then
            log4j_name=$(echo "$env_var" | tr '[:upper:]' '[:lower:]' | tr _ .)
            updateConfig "$log4j_name" "${!env_var}" "$KAFKA_HOME/config/connect-log4j.properties"
        fi
    done
)

# Add all jars in /usr/share/java/converters to classpath
USR_SHARE_CONVERTERS=$(find /usr/share/java/converters -name '*.jar' -type f -printf ':%p\n' | sort -u | tr -d '\n')

export CLASSPATH=$CLASSPATH$USR_SHARE_CONVERTERS

if [[ -n "$CUSTOM_INIT_SCRIPT" ]] ; then
  eval "$CUSTOM_INIT_SCRIPT"
fi

exec "$KAFKA_HOME/bin/connect-distributed.sh" "$KAFKA_HOME/config/connect-distributed.properties"
