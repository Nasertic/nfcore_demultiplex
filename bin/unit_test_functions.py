
import unittest

from samplesheet_check import correct_index, correct_index2, correct_name


class TestCorrectFunctions(unittest.TestCase):

    ## Correct index function
    def test_true_cases_correct_index(self):
        self.assertTrue(correct_index("ATCG"))
        self.assertTrue(correct_index("ATCGATCG"))
        self.assertTrue(correct_index("ATCGATCGATCG"))

    def test_false_cases_correct_index(self):
        self.assertFalse(correct_index("ATCX"))
        self.assertFalse(correct_index("ATCGATCGATCX"))
        self.assertFalse(correct_index("actg"))

    ## Correct index2 function
    def test_true_cases_correct_index2(self):
        self.assertTrue(correct_index2("GGGG", "ATCG"))
        self.assertTrue(correct_index2("GGGGAAA", "ATCGAAA"))

    def test_false_cases_correct_index2(self):
        self.assertFalse(correct_index2("GGGG", "ATC"))
        self.assertFalse(correct_index2("GGGGAAA", "ATCGAAX"))

    ## Correct name function
    def test_true_cases_correct_name(self):
        self.assertTrue(correct_name("sample1"))
        self.assertTrue(correct_name("sample_1"))
        self.assertTrue(correct_name("sample-1"))

    def test_false_cases_correct_name(self):
        self.assertFalse(correct_name("sample 1"))
        self.assertFalse(correct_name("sample/1"))
        self.assertFalse(correct_name("sample*1"))
        self.assertFalse(correct_name("sample`1"))

if __name__ == "__main__":
    unittest.main()
