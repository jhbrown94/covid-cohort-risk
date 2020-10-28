#!python

import csv

daily_new_cases_per_100k = [2.0, 5.0, 10.0, 25.0, 50.0, 100.0]

days_of_infection = 14
pod_size_including_teacher = 13

number_of_students = 2000


# Questions to answer:
#
# 1. What are the odds someone in a pod is infected on day 1, when you first test.
# 2. What is the average length of time before someone in a pod is infected due to community transmission.

# def day_one():


class Result(object):
    def __init__(self, daily_new_cases_per_100k):
        self.daily_new_cases_per_100k = daily_new_cases_per_100k

        self.days_of_infection = days_of_infection
        self.number_of_students = number_of_students
        self.pod_size_including_teacher = pod_size_including_teacher

        self.number_of_pods = self.number_of_students / (
            self.pod_size_including_teacher - 1
        )

        self.p_a_random_person_is_newly_infected_today = (
            self.daily_new_cases_per_100k / 100000.0
        )

        self.p_a_random_person_is_not_newly_infected_today = (
            1.0 - self.p_a_random_person_is_newly_infected_today
        )

        self.p_a_random_person_is_currently_infected = (
            self.p_a_random_person_is_newly_infected_today * self.days_of_infection
        )

        self.p_a_random_person_is_not_infected_today = (
            1.0 - self.p_a_random_person_is_currently_infected
        )

        self.p_a_random_pod_has_no_infections = (
            self.p_a_random_person_is_not_infected_today
            ** self.pod_size_including_teacher
        )

        self.p_a_random_pod_has_at_least_one_infection = (
            1.0 - self.p_a_random_pod_has_no_infections
        )

        self.p_no_pod_has_infections = (
            self.p_a_random_pod_has_no_infections ** self.number_of_pods
        )

        self.p_some_pods_have_infections = 1.0 - self.p_no_pod_has_infections

        self.p_a_random_pod_gets_no_new_infections_today = (
            self.p_a_random_person_is_not_newly_infected_today
            ** self.pod_size_including_teacher
        )

        self.p_a_random_pod_gets_some_new_infections_today = (
            1.0 - self.p_a_random_pod_gets_no_new_infections_today
        )

        self.expected_number_of_days_between_infections_in_a_pod = (
            1.0 / self.p_a_random_pod_gets_some_new_infections_today
        )

        self.p_no_pods_get_new_infections_today = (
            self.p_a_random_pod_gets_no_new_infections_today ** self.number_of_pods
        )

        self.p_some_pods_get_new_infections_today = (
            1.0 - self.p_no_pods_get_new_infections_today
        )

        self.expected_number_of_days_between_new_pod_infection_events = (
            1.0 / self.p_some_pods_get_new_infections_today
        )

    def display(self):
        print("Parameters:")
        print(f"Daily new cases per 100k people: {self.daily_new_cases_per_100k}")
        print(f"Number of calendar days of a COVID infection: {self.days_of_infection}")
        print(f"Pod size(including teacher) {self.pod_size_including_teacher}")
        print(f"Number of students: {self.number_of_students}")
        print()
        print("Derived parameters:")
        print(f"Total number of pods: {self.number_of_pods:.1f}")
        print()

        print(
            f"Chance that a randomly selected person is infected today: {self.p_a_random_person_is_currently_infected * 100.0:.2f}%"
        )
        print(
            f"Chance that a randomly selected pod has one or more infected people on day one: {self.p_a_random_pod_has_at_least_one_infection * 100.0:.2f}%"
        )
        print(
            f"Chance that one or more of the pods has one or more infected people on day one: {self.p_some_pods_have_infections * 100.0:.2f}%"
        )
        print()
        print(
            f"Chance that a randomly selected pod gets one or more new infections on any given calendar day: {self.p_a_random_pod_gets_some_new_infections_today * 100.0:.2f}%"
        )
        print(
            f"Expected number of calendar days between infections in one pod: {self.expected_number_of_days_between_infections_in_a_pod:.1f}"
        )
        print(
            f"Chance that one or more of the pods get one or more new infections on any given calendar day: {self.p_some_pods_get_new_infections_today * 100.0:.2f}%"
        )
        print(
            f"Expected number of calendar days between new infections in one or more pods: {self.expected_number_of_days_between_new_pod_infection_events:.1f}"
        )
        print("\n\n\n\n\n")


def write_csv(results, filename):
    with open(filename, "w", newline="") as csvfile:
        csvwriter = csv.writer(csvfile)

        csvwriter.writerow(["Parameters"])

        csvwriter.writerow(
            ["Daily new cases per 100k people"]
            + [r.daily_new_cases_per_100k for r in results]
        )

        csvwriter.writerow(
            ["Number of calendar days of a COVID infection"]
            + [r.days_of_infection for r in results]
        )
        csvwriter.writerow(
            ["Pod size(including teacher"]
            + [r.pod_size_including_teacher for r in results]
        )
        csvwriter.writerow(
            ["Number of students"] + [r.number_of_students for r in results]
        )
        csvwriter.writerow(["Derived parameters"])

        csvwriter.writerow(
            ["Total number of pods"] + [r.number_of_pods for r in results]
        )

        csvwriter.writerow(["Risks"])
        csvwriter.writerow(
            ["Chance that a randomly selected person is infected today"]
            + [r.p_a_random_person_is_currently_infected for r in results]
        )

        csvwriter.writerow(
            [
                "Chance that a randomly selected pod has one or more infected people on day one"
            ]
            + [r.p_a_random_pod_has_at_least_one_infection for r in results]
        )

        csvwriter.writerow(
            [
                "Chance that one or more of the pods has one or more infected people on day one"
            ]
            + [r.p_some_pods_have_infections for r in results]
        )

        csvwriter.writerow(
            [
                "Chance that a randomly selected pod gets one or more new infections on any given calendar day"
            ]
            + [r.p_a_random_pod_gets_some_new_infections_today for r in results]
        )

        csvwriter.writerow(
            ["Expected number of calendar days between infections in one pod"]
            + [r.expected_number_of_days_between_infections_in_a_pod for r in results]
        )

        csvwriter.writerow(
            [
                "Chance that one or more of the pods get one or more new infections on any given calendar day"
            ]
            + [r.p_some_pods_get_new_infections_today for r in results]
        )

        csvwriter.writerow(
            [
                "Expected number of calendar days between new infections in one or more pods"
            ]
            + [
                r.expected_number_of_days_between_new_pod_infection_events
                for r in results
            ]
        )


if __name__ == "__main__":
    results = []
    for daily_per_100k in daily_new_cases_per_100k:
        result = Result(daily_per_100k)
        result.display()
        results.append(result)
    write_csv(results, "results.csv")
