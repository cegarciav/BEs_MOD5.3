import matplotlib.pyplot as plt
import scipy.io.wavfile as wav
import numpy as np

################################################
#                                              #
#  Initialisation des variables et paramètres  #
#                                              #
################################################

path = "spoken_digit_dataset/"
duree_trame = 0.030
ordre = 10
omega_v, omega_d, omega_h = 1, 1, 1

#########################################################
#                                                       #
#  Lecture et affichage de la forme d'onde d'un signal  #
#                                                       #
#########################################################

def forme_onde(name):
    Fe, s = wav.read(path + name)
    plt.title("Signal Wave...")
    plt.plot(s)
    plt.show()
    
"""forme_onde("0_jackson_0.wav")"""

#################################
#                               #
#  Calcul des coefficients LPC  #
#                               #
#################################

def get_r_vector(window):
    r_vector = []
    for index in range(ordre + 1):
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

def lpc_coeffs(window):
    r_vector = get_r_vector(window)
    r_matrix = get_r_matrix(r_vector)
    a_vector = get_a_vector(r_matrix)
    return a_vector

def lpc_coeffs_list(signal, window_semi_size):
    s_length = len(signal)
    window_size = window_semi_size * 2
    start = 0
    lpc_list = []
    while True:
        window = signal[start : start + window_size]
        lpc_list.append(lpc_coeffs(window))
        start += window_semi_size
        if start + window_size > s_length:
            break
    return lpc_list

"""Fe, s = wav.read(path + "0_jackson_0.wav")
window_semi_size = int(Fe * duree_trame / 2)
coeffs_s = lpc_coeffs_list(s, window_semi_size)"""

###########################################################
#                                                         #
#  Calcul de la matrice des distances entre deux signaux  #
#                                                         #
###########################################################

def euclidean_distance(vect1, vect2):
    return np.sqrt(sum((vect1 - vect2) ** 2))

def matrice_distances(coeffs_1, coeffs_2):
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
    for j in range(1, len(distance_matrix[0])):
        for i in range(1, len(distance_matrix)):
            dist_h = distance_matrix[i,j-1] + omega_h * euclidean_distance(coeffs_1[i], coeffs_2[j])
            dist_v = distance_matrix[i-1,j] + omega_v * euclidean_distance(coeffs_1[i], coeffs_2[j])
            dist_d = distance_matrix[i-1,j-1] + omega_d * euclidean_distance(coeffs_1[i], coeffs_2[j])
            distance_matrix[i,j] = min(dist_h, dist_v, dist_d)
    # on retourne la matrice des distances
    return distance_matrix


""" TEST """

Fe, s1 = wav.read(path + "0_jackson_0.wav")
_, s2 = wav.read(path + "1_jackson_0.wav")
window_semi_size = int(Fe * duree_trame / 2)
coeffs_s1 = lpc_coeffs_list(s1, window_semi_size)
coeffs_s2 = lpc_coeffs_list(s2, window_semi_size)
matrice = matrice_distances(coeffs_s1, coeffs_s2)
distance_optimale = matrice[-1,-1] / (len(coeffs_s1) + len(coeffs_s2))
#print(matrice)
print('Distance optimale : ' + str(distance_optimale))
