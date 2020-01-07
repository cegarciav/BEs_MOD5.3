import scipy.io.wavfile as wav
import numpy as np

def get_r_vector(order, window):
    r_vector = []
    for index in range(order + 1):
        vect_1 = window[:len(window) - index]
        vect_2 = window[index:]
        r_vector.append(sum(vect_1 * vect_2) / len(vect_1))
    return r_vector

def get_r_matrix(r_vector):
    size = len(r_vector)
    mat = np.zeros((size, size))
    for i in range(size):
        for j in range(size):
            mat[i, j] = r_vector[abs(i - j)]
    return mat

def get_a_vector(matrix):
    inverse_m = np.linalg.inv(matrix)
    sigma_vector = np.zeros(len(matrix))
    sigma_vector[0] = 1
    mult = np.dot(inverse_m, sigma_vector)
    a_vector = mult / mult[0]
    return a_vector[1:]

def lpc_coeffs(order, window):
    r_vector = get_r_vector(order, window)
    r_matrix = get_r_matrix(r_vector)
    a_vector = get_a_vector(r_matrix)
    return a_vector

def lpc_coeffs_list(signal, window_semi_size):
    s_length = len(signal)
    window_size = window_semi_size * 2
    start = 0
    lpc_list = []
    while True:
        window = s[start, start + window_size]
        lpc_list.append(lpc_coeffs(order, window))
        start += window_semi_size
        if start + window_size > s_length:
            break
    return lpc_list

def euclidean_distance(vect1, vect2):
    return np.sqrt(sum((vect1 - vect2) ** 2))

def distance_elastique(coeffs_1, coeffs_2):
    distance_matrix = np.zeros((len(coeffs_1), len(coeffs_2)))
    # on calcule la première distance (0,0)
    distance_matrix[0,0] = euclidean_distance(coeffs_1[0], coeffs_2[0])
    # on calcule le long de la première colonne
    for i in range(1, len(distance_matrix)):
        distance_matrix[i,0] = distance_matrix[i-1,0] + omega_v * euclidean_distance(coeffs_1[i], coeffs_2[0])
    # on calcule le long de la première ligne
    for j in range(1, len(distance_matrix[0])):
        distance_matrix[0,j] = distance_matrix[0,j-1] + omega_h * euclidean_distance(coeffs_1[0], coeffs_2[j])
    # on calcule pour le reste du tableau
    for i in range(1, len(distance_matrix[0])):
        for j in range(1, len(distance_matrix)):
            dist_h = distance_matrix[i,j-1] + omega_h * euclidean_distance(coeffs_1[i], coeffs_2[j])
            dist_v = distance_matrix[i-1,j] + omega_v * euclidean_distance(coeffs_1[i], coeffs_2[j])
            dist_d = distance_matrix[i-1,j-1] + omega_d * euclidean_distance(coeffs_1[i], coeffs_2[j])
            distance_matrix[i,j] = min(dist_h, dist_v, dist_d)
    # on retourne la distance optimale
    return distance_matrix[-1,-1] / (len(coeffs_1) + len(coeffs_2))

order = 10
omega_v = 1
omega_d = 1
omega_h = 1

files_folder = "spoken_digit_dataset/"
Fe, s = wav.read(files_folder + "0_jackson_0.wav")
_, s2 = wav.read(files_folder + "0_jackson_5.wav")
window_semi_size = int(Fe * 0,030 / 2)

"""
semi_max_size = int(Fe * 0,03 / 2)
semi_min_size = int(Fe * 0,02 / 2)
chosen_window_semi_size = [s_length % semi_min_size, semi_min_size]
for window_semi_size in range(semi_min_size + 1, semi_max_size + 1):
    current_leftovers = s_length % window_semi_size
    if current_leftovers < chosen_window_semi_size[0]:
        chosen_window_semi_size = [current_leftovers, window_semi_size]
window_semi_size = chosen_window_semi_size[1]
window_size = window_semi_size * 2
"""

coeffs_1 = lpc_coeffs_list(s, window_semi_size)
coeffs_2 = lpc_coeffs_list(s2, window_semi_size)
distance = distance_elastique(coeffs_1, coeffs_2)



    
    
