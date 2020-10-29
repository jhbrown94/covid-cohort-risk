# Student cohort community risk impact assessment tool

## Overview

As part of COVID-19 response, some schools are dividing students into "cohorts" for in-person learning. Students and teachers in a cohort meet only with one another. This strategy is intended to limit the number of people exposed to a person who is positive COVID-19 in a school -- if someone in a cohort acquires COVID-19 in the community, only the people in that cohort need to subsequently quarantine and test.

In a "cohort" strategy, the probability of having one person of a cohort positive for COVID-19 is dependent on: community transmission rates, size of cohort. The probability of having a cohort in a district test positive depends on these factors, as well as the number of cohorts.

This is a simple tool to help schools evaluate how often an individual cohort is likely to have a COVID-positive person or people in it, and how often one or more cohorts, out of many in a district, are likely to have COVID-positive people in them.

## Building

This tool is written in Elm, which compiles to Javascript. Install the [Elm toolchain](https://guide.elm-lang.org/install/elm.html).

This tool is packaged with `parcel`. Install parcel with `npm`.

## Running locally

Run `parcel index.html`

Visit `localhost:1234`

## Packaging for distribution

Run `parcel build index.html` You may need additional parcel options depending on where and how you are hostiing this.
