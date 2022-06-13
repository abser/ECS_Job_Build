#!/bin/bash
####################################
# DOCKER
###################################

# Build docker image
echo "Building docker image ..." && \
ECR_URL_TARGET="046729567527.dkr.ecr.ap-southeast-1.amazonaws.com/monarch"
APP_NAME="monarch"
NODE_ENV="production"
AWS_PROFILE="jenkins-sit"
CLUSTER_NAME="MonarchECSCluster"
SERVICE_NAME="test-app"
REGION="ap-southeast-1"
#FAMILY=`sed -n 's/.*"family": "\(.*\)",/\1/p' task_def.json`
FAMILY="test-app"
echo $USER
Docker=`aws ecr get-login-password --region $REGION`
echo "Logging into target ECR ($AWS_PROFILE_TARGET)" && \
docker login -u AWS -p ${Docker} https://${ECR_URL_TARGET} && \

docker build -t ${APP_NAME}:${VERSION_NUMBER} .

docker tag ${APP_NAME}:${VERSION_NUMBER} ${ECR_URL_TARGET}:${VERSION_NUMBER} && \

echo "Pushing into target ECR"
docker push ${ECR_URL_TARGET}:${VERSION_NUMBER}


# Inject new docker image version URL into new task defination
sed -i "s+{{DOCKER_IMAGE_URL}}+$ECR_URL_TARGET:$VERSION_NUMBER+g" ./task_def.json

# Add the new task defination
NEW_TASK_DEFINITION=$(aws ecs register-task-definition --cli-input-json file://./task_def.json --region $REGION) && \

# Get new task defination ARN
NEW_TASK_ARN=$(echo "$NEW_TASK_DEFINITION" | jq '.taskDefinition.taskDefinitionArn' | sed -e 's/^"//' -e 's/"$//') && \
echo "New task definition: $NEW_TASK_ARN"

if test -z "$NEW_TASK_ARN"
then
  echo "Abort deployment missing task ARN"
  exit 1
fi

SERVICES=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER_NAME} --region ${REGION} | jq .failures[]`
echo "SERVICES: $SERVICES"
#Get latest revision
REVISION=`aws ecs describe-task-definition --task-definition ${NEW_TASK_ARN} --region ${REGION} | jq .taskDefinition.revision`
echo "REVISION: $REVISION"
#Create or update service
if [ "$SERVICES" == "" ]; then
  echo "entered existing service"
  DESIRED_COUNT=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER_NAME} --region ${REGION} | jq .services[].desiredCount`
  if [ "${DESIRED_COUNT}" == "0" ]; then
    DESIRED_COUNT="1"
  fi
  aws ecs update-service --region ${REGION} --cli-input-json file://./update_service.json
else
  echo "entered new service"
  aws ecs create-service --cli-input-json file://./create_service.json  --region ${REGION} 
fi
