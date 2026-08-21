import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "src"))

import pandas as pd
from impact import impact, list_codesystems, list_ltcs


def main():
    """Run admission- and person-level IMPACT examples."""
    assert len(list_codesystems()) >= 13
    assert list_ltcs().shape == (321, 6)

    columns = [
        "hesid",
        "epikey",
        *(f"diag_{number:02d}" for number in range(1, 11)),
        *(f"opertn_{number:02d}" for number in range(1, 6)),
    ]

    # Load a selection of Hospital Episode Statistics (HES) Admitted Patient Care (APC)-like data for evaluation
    synthetic_hes_rows = [
        '"0gPOSCcbVKJngURUaSZXYCRNLLXE" "867770817181" "R69X" "E780" "C787" "I209" "K750" "K219" ""     ""     ""     ""     "X729" ""     ""     ""     ""',
        '"1wmyri0HQA7xMbXVZ3ZGaDkaNizI" "369793263375" "M169" "Z115" "Z115" "N179" "O700" "E119" "Y871" "Z922" ""     ""     "U212" "Y793" "Z063" ""     ""',
        '"1wmyri0HQA7xMbXVZ3ZGaDkaNizI" "690303771232" "G510" "R101" "I10X" "F329" "R568" "Z115" ""     ""     ""     ""     "U354" "Z284" ""     ""     ""',
        '"3YFiC4AmI1rNW2BUtjvnyZ4vVaOi" "530304528232" "T795" "Z370" "I10X" "B182" "Z864" ""     ""     ""     ""     ""     "R249" "Z942" ""     ""     ""',
        '"4lVM8NmNyP405EiboQyg4nxsdP85" "708094304417" "L989" "I10X" "E039" "J459" "I350" "I489" "G952" "I451" "J984" ""     "U051" "Z942" "Y714" ""     ""',
        '"4nzXgVgFrDjaI0oJCyFh6ewL2B20" "210414688561" "K819" "K573" "O429" "I259" "R478" ""     ""     ""     ""     ""     "T242" "Y534" ""     ""     ""',
        '"4nzXgVgFrDjaI0oJCyFh6ewL2B20" "325931722074" "N185" "G551" "E859" "J459" "Z864" "K449" ""     ""     ""     ""     "C605" ""     ""     ""     ""',
        '"4nzXgVgFrDjaI0oJCyFh6ewL2B20" "237835606385" "J386" "Q729" "K227" "A419" "N40X" "E835" ""     ""     ""     ""     "X724" "E047" ""     ""     ""',
        '"8KEoz93p4ByE1MBbJcbBrL1ky55I" "78967435732"  "U071" "M255" "I10X" "I10X" "Z922" "H492" "I959" ""     ""     ""     "X729" "Y131" "U212" "S571" ""',
        '"8KEoz93p4ByE1MBbJcbBrL1ky55I" "885042795467" "M171" "O240" "G409" "M179" "F171" ""     ""     ""     ""     ""     "W401" "O302" ""     ""     ""',
        '"95bLmQZ5JQMTJDtC3zUMtWWt4onX" "130589533121" "K509" "F329" "R268" "I10X" "F101" "Z864" ""     ""     ""     ""     "X495" ""     ""     ""     ""',
        '"95bLmQZ5JQMTJDtC3zUMtWWt4onX" "825769857811" "J181" "J181" "C786" "E162" "Z864" ""     ""     ""     ""     ""     "X332" ""     ""     ""     ""',
        '"95bLmQZ5JQMTJDtC3zUMtWWt4onX" "578872650200" "R55X" "Z370" "K449" "R798" "Z904" "I269" "I10X" ""     ""     ""     ""     ""     ""     ""     ""',
        '"95bLmQZ5JQMTJDtC3zUMtWWt4onX" "614829204733" "R69X" "R11X" "Z115" "E039" "K802" "F171" ""     ""     ""     ""     ""     ""     ""     ""     ""',
        '"CzNmlrfnoyuvLDJWTjPSkudWUjQB" "341422581011" "A419" "C793" "I489" "R18X" ""     ""     ""     ""     ""     ""     "H206" "C712" "U054" ""     ""',
        '"E3EiJI0yJpBUrJbrI6zYzYIiDUNK" "728741299521" "R69X" "F171" "T510" "Z824" "Z853" "I693" "Z874" ""     ""     ""     "X403" ""     ""     ""     ""',
        '"IXWlaOLJlmBjo0CxShd6z3jTBZDc" "231761840622" "N390" "J690" "C787" ""     ""     ""     ""     ""     ""     ""     "Y388" ""     ""     ""     ""',
        '"IwVjmuM6gv16Tk5Itl8Mw5G8Hpy7" "296702357395" "N185" "I252" "C61X" ""     ""     ""     ""     ""     ""     ""     "X292" "Z421" ""     ""     ""',
        '"M17B5DK7viVo5GH5gQsGs1xI0Vrf" "15852626156"  "N920" "S028" "Z115" "M796" "Z507" "I251" ""     ""     ""     ""     "Z942" ""     ""     ""     ""',
        '"M17B5DK7viVo5GH5gQsGs1xI0Vrf" "746166540675" "C97X" "E876" "I10X" "I730" "Z850" "Z886" ""     ""     ""     ""     "L914" ""     ""     ""     ""',
        '"NJZrw1mrliQKq4N55vjOc7EdGDWG" "951293046545" "N488" "D462" "Z874" "J90X" "M819" "I10X" "R042" "Z867" ""     ""     "G451" "Y535" "Z942" ""     ""',
        '"NJZrw1mrliQKq4N55vjOc7EdGDWG" "740132120357" "D509" "B961" "D649" "L97X" ""     ""     ""     ""     ""     ""     ""     ""     ""     ""     ""',
        '"NJZrw1mrliQKq4N55vjOc7EdGDWG" "489877494363" "C921" "I251" "I10X" "I509" "J90X" "E872" ""     ""     ""     ""     "G475" "Z943" ""     ""     ""',
        '"NmBPWYs9QJWe6sSO9sork0qofqXr" "159654788477" "E871" "A419" "I429" "B962" "I10X" "Z850" ""     ""     ""     ""     "H012" "Y973" "Z283" ""     ""',
        '"POgrg02diU3PWsU0UzPhtB90Jaf7" "858663710065" "O688" "I10X" "J459" "I10X" "I10X" "H360" "Z888" "Z864" ""     ""     "G451" "Z274" ""     ""     ""',
        '"RBy7EEpmZC4q4fm5S8T8hZ1Yv6yJ" "234492410063" "R002" "D508" "J47X" "E119" "I10X" "Z870" "N26X" "Z866" ""     ""     ""     ""     ""     ""     ""',
        '"RMwq5LvzNQMrxekHQIkYU3yQyyey" "763687955512" "S021" "F001" "J90X" "P590" "I444" "Z922" ""     ""     ""     ""     "M479" ""     ""     ""     ""',
        '"RMwq5LvzNQMrxekHQIkYU3yQyyey" "696934557396" "R51X" "J90X" "E119" "Z130" "F419" "I739" ""     ""     ""     ""     "C751" "Z665" ""     ""     ""',
        '"ROzOLQm4Gkh8JqvgkE1XOLRsfkn0" "226422592017" "T855" "I501" "K760" ""     ""     ""     ""     ""     ""     ""     "Z284" "Z286" "Z942" ""     ""',
        '"RPU6A0JZ3iIHGt8lpwXjhkeKaYJF" "848787640735" "R69X" "S010" "I10X" "I209" "Z507" "Z926" ""     ""     ""     ""     "T272" ""     ""     ""     ""',
        '"RPU6A0JZ3iIHGt8lpwXjhkeKaYJF" "257726533866" "Q052" "E119" "R263" "F329" "R296" "K590" "Z991" "Z223" "Z867" ""     "Z943" ""     ""     ""     ""',
        '"S8X1Z5piBYDM5nU02kQx57WtN0AG" "224311180020" "D619" "R391" "E119" "R54X" "Z907" "Z864" ""     ""     ""     ""     "Z286" ""     ""     ""     ""',
        '"WoOIzdei6mIcqW2T9Pv5nvZRcPPl" "770039934159" "K519" "I209" "I10X" "H919" "I209" "G938" "Z955" "Z960" ""     ""     ""     ""     ""     ""     ""',
        '"YhGAPXlzCUQs3fuAUeM0uijZ8U2V" "305962168802" "K409" "F058" "K573" "Z515" "Z922" ""     ""     ""     ""     ""     "X362" ""     ""     ""     ""',
        '"ZDP7NxgaCpFf8l1W35mY5HOvgVkm" "975405964717" "K409" "E119" "N832" "R14X" "G35X" "Z880" "Z866" "Z115" "M419" "K579" "Z282" ""     ""     ""     ""',
        '"ZYgAq9sxrKUT6mepjzUCS1cgLRL2" "275528897878" "J980" "J22X" "W190" "I739" "K573" ""     ""     ""     ""     ""     "Z291" "Z905" ""     ""     ""',
        '"anwzBZKZ2QYeonx40h6uULp64lSB" "477883859782" "P070" "B951" "E669" "I517" "Z880" "I10X" "L248" "Z866" ""     ""     "U223" ""     ""     ""     ""',
        '"anwzBZKZ2QYeonx40h6uULp64lSB" "138474844582" "R074" "O721" "J459" "N390" "I259" "K802" "M518" ""     ""     ""     "H201" "Z501" "Z493" ""     ""',
        '"cL3hq1W06Yo4ouHTetEQxbBfYFFI" "560783282060" "O268" "L031" "G231" "F419" "Z867" "M549" ""     ""     ""     ""     "U052" ""     ""     ""     ""',
        '"cXJy5NA8nEhM0hFGEYqn49tSxP2i" "444600374877" "K137" "Q381" "K509" "I801" ""     ""     ""     ""     ""     ""     ""     ""     ""     ""     ""',
        '"d760rVjcX6NK4b71FzeWBNnA6UUy" "903591883291" "M060" "K920" "I498" "Z115" ""     ""     ""     ""     ""     ""     "Y981" ""     ""     ""     ""',
        '"ddIgpD22WzdbQRhQjpnuEGDmCNck" "478174100583" "M139" "L089" "Z922" "Z921" "Z850" "Z507" "Z864" "L248" "I10X" ""     "G451" "U362" ""     ""     ""',
        '"dmRCR8d0460A5bRyuty3m2mJfNCS" "940987692471" "H71X" "F845" "I10X" "M199" "N189" ""     ""     ""     ""     ""     "C794" ""     ""     ""     ""',
        '"hVC1iitgeN4idS7bHylxQ2YCNpGB" "495323644469" "R91X" "T815" "I10X" "R53X" "K567" "U073" "Z955" ""     ""     ""     "Z942" ""     ""     ""     ""',
        '"hVmI3yFldRVoxNLgwnKPybHikOYi" "462889792775" "L400" "F03X" "R458" "C787" "E559" "M316" "Z921" ""     ""     ""     "C751" "Z941" ""     ""     ""',
        '"hblfYufiX8kE9WRcEbaFXlKswHA4" "71832324142"  "K746" "R13X" "Z988" "I10X" "E86X" ""     ""     ""     ""     ""     "Z411" ""     ""     ""     ""',
        '"icdlGgqhnSvWKBfSzzWThCscxP9Y" "321876853267" "R69X" "R074" "E780" "E039" "O212" "Z804" "E115" "Z864" "I500" ""     "Y981" "O161" ""     ""     ""',
        '"j1DaU4Bs2X33MDYVPXUOkDT0ea3O" "946770779966" "P228" "K573" "R074" "J459" "N182" ""     ""     ""     ""     ""     ""     ""     ""     ""     ""',
        '"kbY9cS0nudi52g3pTef09u14y5xk" "939259770312" "I209" "R21X" "Z921" "Z922" "L891" ""     ""     ""     ""     ""     "Z284" ""     ""     ""     ""',
        '"mf2ndH48ZY6F4expvzgelwBsJ6Zh" "798129444430" "R91X" "K449" "M819" ""     ""     ""     ""     ""     ""     ""     "Z943" ""     ""     ""     ""',
        '"mf2ndH48ZY6F4expvzgelwBsJ6Zh" "158210013321" "T391" "T810" "I259" "Z864" ""     ""     ""     ""     ""     ""     ""     ""     ""     ""     ""',
        '"mf2ndH48ZY6F4expvzgelwBsJ6Zh" "763834980331" "T840" "B956" "W185" "Z854" "N189" "K760" "Z921" "E538" ""     ""     "Z274" ""     ""     ""     ""',
        '"n9E2gPm0og60e2vm3iyPfPlPlVLm" "640533764421" "Z080" "I10X" "E039" "F171" "I517" "L97X" "Z923" "L248" ""     ""     "Z272" "Z926" ""     ""     ""',
        '"n9E2gPm0og60e2vm3iyPfPlPlVLm" "214412345430" "K298" "F009" "M199" "N183" "N182" "E119" "Z864" "I10X" "Z833" ""     "Y981" "Z924" ""     ""     ""',
        '"orJqyIFFTWv7xRDWvo5dymUI6cqI" "296687323869" "C20X" "T393" "R11X" "I652" "F419" "N184" "I10X" ""     ""     ""     "H221" ""     ""     ""     ""',
        '"pjspLa7BXdSbqkxoYfq8bwLLDqjp" "772183086398" "R69X" "K219" "E113" "K579" "K659" ""     ""     ""     ""     ""     "G451" ""     ""     ""     ""',
        '"qG6J9uX8JnNJINl0VWNi49t7Tn1S" "304591817822" "R69X" "I861" "K102" "Z864" "K573" "Z223" ""     ""     ""     ""     "X332" "Z846" "H232" "Z272" ""',
        '"rVN25XsFiKd1DHewzQTTaRnjIzQb" "987442266183" "R398" "F140" "N281" ""     ""     ""     ""     ""     ""     ""     "C828" "Z942" ""     ""     ""',
        '"rlnEYDJX3Ri18P2bMGiIDh97yArQ" "972509452793" "N390" "Z491" "M414" "F191" "Z858" "J449" ""     ""     ""     ""     "Z603" ""     ""     ""     ""',
        '"u395nEKAjp9gp5ItOGOIZGaOxyYW" "964174344879" "R222" "V184" "J181" "Z880" "E039" ""     ""     ""     ""     ""     ""     ""     ""     ""     ""',
        '"uCZ6jb7kPIWapsBXWjVsxzpyDAKN" "50210016108"  "C341" "N328" "E669" "F209" "R296" "M469" "I259" ""     ""     ""     "H229" ""     ""     ""     ""',
        '"vGp258Gg6iky9ZSJ1EdtnumPZRCl" "99775879820"  "I489" "C798" "F329" ""     ""     ""     ""     ""     ""     ""     "E147" ""     ""     ""     ""',
        '"wFdq1T239RKlh7Ji6jiwDnuJZzsG" "311969997357" "H269" "Z864" "G473" "Z921" ""     ""     ""     ""     ""     ""     "Z926" ""     ""     ""     ""',
        '"wFdq1T239RKlh7Ji6jiwDnuJZzsG" "502031955061" "G35X" "Z923" "I10X" "D860" "E039" "I517" "F171" ""     ""     ""     "T122" "Z272" ""     ""     ""',
        '"wFdq1T239RKlh7Ji6jiwDnuJZzsG" "101209690674" "F103" "W190" "F019" "D649" "I10X" "K579" ""     ""     ""     ""     "U162" ""     ""     ""     ""',
        '"xqQ1LfwTBdS12UkbJv0YwvExn1v3" "236319153063" "S424" "C798" "K047" "K743" "F171" "Z962" "Z904" "U073" "E780" ""     "Y981" "Y981" ""     ""     ""',
        '"xqQ1LfwTBdS12UkbJv0YwvExn1v3" "673943835932" "K088" "M509" "O757" "K590" "R296" "H191" ""     ""     ""     ""     "E061" ""     ""     ""     ""',
        '"yLrEE7fvp0zkbmBGpChR4NDqJouh" "65636008419"  "N185" "Z370" "G20X" "J981" "Z880" "Z955" ""     ""     ""     ""     "R249" "M292" ""     ""     ""',
        '"yLrEE7fvp0zkbmBGpChR4NDqJouh" "482615460882" "O368" "E876" "J439" "D510" "Z888" "J459" ""     ""     ""     ""     "M702" ""     ""     ""     ""',
        '"z4yHVoyb6uyrFeONLnzXFakjk3Oh" "687864870336" "N431" "Z121" "Z871" "Z966" "Z880" "Z861" "Z907" ""     ""     ""     ""     ""     ""     ""     ""',
        '"z4yHVoyb6uyrFeONLnzXFakjk3Oh" "485579611714" "O031" "R072" "Z880" "I678" "E559" "I489" "R000" ""     ""     ""     "G451" "Y981" "Z413" ""     ""'
    ]

    records = [re.findall(r'"([^"]*)"', line) for line in synthetic_hes_rows]
    assert all(len(record) == len(columns) for record in records)
    events = pd.DataFrame(records, columns=columns)
    assert len(events) == 71
    assert events["epikey"].is_unique

    diagnosis_columns = events.filter(regex=r"^diag_").columns.tolist()
    operation_columns = events.filter(regex=r"^opertn_").columns.tolist()

    # HES stores ICD-10 and OPCS-4 values without decimal points. IMPACT
    # definitions use classification notation, so insert the decimal after the
    # third character in a working copy while leaving the source unchanged.
    def add_classification_decimal(code):
        return f"{code[:3]}.{code[3]}" if len(code) == 4 else code

    impact_events = events.copy()
    code_columns = diagnosis_columns + operation_columns
    for column in code_columns:
        impact_events[column] = impact_events[column].map(
            add_classification_decimal
        )

    # ICD-10 is applied to diagnosis fields and OPCS-4 to procedure fields.
    admission_out = impact(
        impact_events,
        id="epikey",
        codesystems=["icd10", "opcs4"],
        searchvars=[diagnosis_columns, operation_columns],
        level="phenotype",
        multimorbidity=True,
        summary=True,
    )
    assert admission_out["epikey"].equals(events["epikey"])
    admission_out = pd.concat([events[["hesid"]], admission_out], axis=1)

    # IMPACT calculates these grouped-phenotype counts independently for every
    # admission row, using all diagnosis and procedure fields specified above.
    count_columns = [
        "hesid",
        "epikey",
        "__nphenotypes",
        "__nmental",
        "__nphysical",
        "__nbody",
    ]
    print(admission_out[count_columns].to_string(index=False))
    admission_counts = admission_out.set_index("epikey")["__nphenotypes"]
    assert admission_counts.loc["867770817181"] == 4
    assert admission_counts.loc["708094304417"] == 7
    assert admission_counts.loc["687864870336"] == 0

    phenotype_columns = [
        column
        for column in admission_out.columns
        if re.fullmatch(r"__[A-Z0-9]{4}", column)
    ]
    expected_counts = admission_out[phenotype_columns].sum(axis=1)
    assert (expected_counts == admission_out["__nphenotypes"]).all()

    # IMPORTANT: IMPACT output and phenotype counts above are admission-level.
    # For person-level multimorbidity, take the maximum of every phenotype flag
    # across a person's admissions, then recalculate the grouped-phenotype
    # count.
    person_out = (
        admission_out[["hesid", *phenotype_columns]]
        .groupby("hesid", as_index=False, sort=True)
        .max()
    )
    person_out["__nphenotypes"] = person_out[phenotype_columns].sum(axis=1)
    person_out["multimorbidity"] = person_out["__nphenotypes"] >= 2
    print(
        person_out[["hesid", "__nphenotypes", "multimorbidity"]].to_string(
            index=False
        )
    )

    person_counts = person_out.set_index("hesid")
    assert len(person_out) == 50
    assert person_counts.loc[
        "4nzXgVgFrDjaI0oJCyFh6ewL2B20", "__nphenotypes"
    ] == 13
    assert person_counts.loc[
        "n9E2gPm0og60e2vm3iyPfPlPlVLm", "__nphenotypes"
    ] == 11
    assert not person_counts.loc[
        "IXWlaOLJlmBjo0CxShd6z3jTBZDc", "multimorbidity"
    ]

    print("OK: IMPACT Python HES APC example passed")


if __name__ == "__main__":
    main()
