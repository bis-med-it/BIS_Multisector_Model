# The BIS Multisector Model: A Multi-Country Environment for Macroeconomic Analysis

This repository accompanies our paper, **“The BIS Multisector Model: A Multi-Country Environment for Macroeconomic Analysis”**, authored by Matthias Burgert, Giulio Cornelli, Burcu Erik, Benoit Mojon, Daniel Rees and Matthias Rottner.

The paper introduces the BIS Multisector Model (BIS-MS), a dynamic stochastic general equilibrium (DSGE) model for analyzing macroeconomic dynamics in a multi-sector production network. The model can be calibrated to match the input-output data of more than 80 economies, enabling a detailed exploration of sectoral interdependencies and cross-industry shock transmission. The accompanying model toolbox equips policymakers and researchers with an easy-to-access platform for flexible scenario analysis. You can access the full paper [here](https://www.bis.org/publ/work1297.htm).

## How to Run

To use the toolbox, the users need **MATLAB**, the **MATLAB Optimization Toolbox**, and **Dynare version 5.5**. Please refer to the learning guide (BIS_Multisector_Model_Learning_Guide.pdf), which demonstrates the toolbox's capabilities through practical examples. The guide includes two key use cases:
1. Simulating a temporary shock.
2. Simulating a structural change in the economy.

These examples provide step-by-step instructions to help users effectively navigate and utilize the toolbox.

## Data Sources

This repository uses data from the following sources:
1. OECD Inter-Country Input-Output Tables: 2023 release (accessed on 20.11.2023), 2025 edition (accessed on 12.01.2026), [url](https://www.oecd.org/en/data/datasets/inter-country-input-output-tables.html)

2. ADB Multiregional Input-Output Tables (accessed on 03.07.2024), [url](https://kidb.adb.org/globalization/current)

3. U.S. Bureau of Economic Analysis, "The Use of Commodities by Industries" (accessed on 27.09.2023), [url](https://apps.bea.gov/iTable/?reqid=1602&step=6&Categories=IoUnderlying&isURI=1&_gl=1*1e6wj32*_ga*MTExMDM0NjIwMi4xNzQ1OTMyNTYz*_ga_J4698JNNFT*czE3NzQzNDEwMzAkbzQkZzEkdDE3NzQzNDE4ODQkajE1JGwwJGgw#eyJhcHBpZCI6MTYwMiwic3RlcHMiOlsxLDIsMyw0LDRdLCJkYXRhIjpbWyJjYXRlZ29yaWVzIiwiQVIiXSxbIlRhYmxlX0xpc3QiLCJVc2VBUlBybyJdLFsiUmJEZXRhaWxMdmwiLCJTVU0iXSxbIkxhc3RfWWVhciIsIjIwMTkiXSxbIlJvd3MiLFsiQUxMIiwiMTExQ0EiLCIxMTNGRiIsIjIxMSIsIjIxMiIsIjIxMyIsIjIyIiwiMjMiLCIzMjEiLCIzMjciLCIzMzEiLCIzMzIiLCIzMzMiLCIzMzQiLCIzMzUiLCIzMzYxTVYiLCIzMzY0T1QiLCIzMzciLCIzMzkiLCIzMTFGVCIsIjMxM1RUIiwiMzE1QUwiLCIzMjIiLCIzMjMiLCIzMjQiLCIzMjUiLCIzMjYiLCI0MiIsIjQ0MSIsIjQ0NSIsIjQ1MiIsIjRBMCIsIjQ4MSIsIjQ4MiIsIjQ4MyIsIjQ4NCIsIjQ4NSIsIjQ4NiIsIjQ4N09TIiwiNDkzIiwiNTExIiwiNTEyIiwiNTEzIiwiNTE0IiwiNTIxQ0kiLCI1MjMiLCI1MjQiLCI1MjUiLCJIUyIsIk9SRSIsIjUzMlJMIiwiNTQxMSIsIjU0MTUiLCI1NDEyT1AiLCI1NSIsIjU2MSIsIjU2MiIsIjYxIiwiNjIxIiwiNjIyIiwiNjIzIiwiNjI0IiwiNzExQVMiLCI3MTMiLCI3MjEiLCI3MjIiLCI4MSIsIkdGR0QiLCJHRkdOIiwiR0ZFIiwiR1NMRyIsIkdTTEUiLCJVc2VkIiwiT3RoZXIiLCJUT1QiLCJWMDAxIiwiVjAwMiIsIlYwMDMiLCJUT1QiLCJUT1QiXV0sWyJDb2x1bW5zIixbIkFMTCIsIjExMUNBIiwiMTEzRkYiLCIyMTEiLCIyMTIiLCIyMTMiLCIyMiIsIjIzIiwiMzIxIiwiMzI3IiwiMzMxIiwiMzMyIiwiMzMzIiwiMzM0IiwiMzM1IiwiMzM2MU1WIiwiMzM2NE9UIiwiMzM3IiwiMzM5IiwiMzExRlQiLCIzMTNUVCIsIjMxNUFMIiwiMzIyIiwiMzIzIiwiMzI0IiwiMzI1IiwiMzI2IiwiNDIiLCI0NDEiLCI0NDUiLCI0NTIiLCI0QTAiLCI0ODEiLCI0ODIiLCI0ODMiLCI0ODQiLCI0ODUiLCI0ODYiLCI0ODdPUyIsIjQ5MyIsIjUxMSIsIjUxMiIsIjUxMyIsIjUxNCIsIjUyMUNJIiwiNTIzIiwiNTI0IiwiNTI1IiwiSFMiLCJPUkUiLCI1MzJSTCIsIjU0MTEiLCI1NDE1IiwiNTQxMk9QIiwiNTUiLCI1NjEiLCI1NjIiLCI2MSIsIjYyMSIsIjYyMiIsIjYyMyIsIjYyNCIsIjcxMUFTIiwiNzEzIiwiNzIxIiwiNzIyIiwiODEiLCJHRkdEIiwiR0ZHTiIsIkdGRSIsIkdTTEciLCJHU0xFIiwiVE9UIiwiRjAxMCIsIkYwMlMiLCJGMDJFIiwiRjAyTiIsIkYwMlIiLCJGMDMwIiwiRjA0MCIsIkYwNTAiLCJGMDZDIiwiRjA2UyIsIkYwNkUiLCJGMDZOIiwiRjA3QyIsIkYwN1MiLCJGMDdFIiwiRjA3TiIsIkYxMEMiLCJGMTBTIiwiRjEwRSIsIkYxME4iLCJUT1QiLCJUT1QiXV1dfQ==
)

4. U.S. Bureau of Labor Statistics, "Employment and Output by Industry" (accessed on 02.10.2023), [url](https://www.bls.gov/emp/tables/industry-employment-and-output.htm)

Please ensure proper attribution to each source as per their terms of use.

## Licence Note

This repository is released under the Apache License 2.0, as specified in the LICENSE file. However, data from external sources (e.g., OECD, ADB, BEA, and BLS) are subject to their respective terms of use and are not covered by the Apache License 2.0. Users must comply with the licensing and attribution requirements of each data source, as outlined in their terms of use, when using or sharing the data.

## Disclaimer 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
