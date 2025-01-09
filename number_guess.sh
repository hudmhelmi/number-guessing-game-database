#!/bin/bash

# allow db access
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# randomly generate a number
RANDOM_NUMBER=$(( RANDOM % 1000 + 1 ))

# prompt for username
echo "Enter your username:"
read USERNAME

# check if user exists
USER_ID=$($PSQL "SELECT id FROM users WHERE username='$USERNAME'")

# if user does not exist
if [[ -z $USER_ID ]]; then
  # add new user (suppress output)
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)" > /dev/null 2>&1
  # get new user id
  USER_ID=$($PSQL "SELECT id FROM users WHERE username='$USERNAME'")
  # welcome new user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # welcome user back
  RESULT=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")
  GAMES_PLAYED=$(echo "$RESULT" | cut -d '|' -f 1)
  BEST_GAME=$(echo "$RESULT" | cut -d '|' -f 2)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

NUMBER_OF_GUESSES=0

# print the initial guessing prompt once
echo "Guess the secret number between 1 and 1000:"

while true; do
  # read user's guess
  read GUESS

  # if not integer
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  # if guess lower than number
  if (( GUESS < RANDOM_NUMBER )); then
    echo "It's higher than that, guess again:"
  # if guess higher than number
  elif (( GUESS > RANDOM_NUMBER )); then
    echo "It's lower than that, guess again:"
  # if guess correct
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"

    # get current stats
    CURRENT_STATS=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")
    CURRENT_GAMES_PLAYED=$(echo "$CURRENT_STATS" | cut -d '|' -f 1)
    CURRENT_BEST_GAME=$(echo "$CURRENT_STATS" | cut -d '|' -f 2)

    # update games played
    NEW_GAMES_PLAYED=$((CURRENT_GAMES_PLAYED + 1))

    # update best game if needed
    if [[ -z "$CURRENT_BEST_GAME" || $NUMBER_OF_GUESSES -lt $CURRENT_BEST_GAME ]]; then
      NEW_BEST_GAME=$NUMBER_OF_GUESSES
    else
      NEW_BEST_GAME=$CURRENT_BEST_GAME
    fi

    # update user record (suppress output)
    $PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NEW_BEST_GAME WHERE username='$USERNAME'" > /dev/null 2>&1
    break
  fi
done
